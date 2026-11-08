#!/usr/bin/env python3
"""Run a solution against an interactor and judge the result.

Usage: interact.py [--live] --kill S --limit S --transcript F --solution-err F --interactor-err F
                   solution interactor input [answer]

The interactor runs as `interactor <input> [<answer>]`. Each program's output is passed on to the
other, and every line is written to the transcript as "> line" (solution) or "< line"
(interactor). With --live, the transcript goes to stderr as it happens and both programs' stderr
passes through instead of going to the files.

The solution's time is its CPU time, so passing data through this script does not count against
it. Both programs are killed after --kill seconds of wall time, or as soon as both have been
waiting for input for a second with nothing passed between them.

Prints one line: <verdict> <status> <seconds> <max-rss-kb> <detail>, where <verdict> is PASS, WA,
TLE, ILE (idle: the solution waited for input that never came), RE or FAIL (interactor error),
and <status> is the solution's exit status as run_timed reports it (124 when killed).
"""

import argparse
import os
import selectors
import signal
import subprocess
import sys
import time

DEADLOCK_SECONDS = 1.0
TICKS = os.sysconf("SC_CLK_TCK")


def proc_stat(pid: int) -> tuple[str, float] | None:
    """The process's state letter and CPU seconds so far, or None once it is gone."""
    try:
        with open(f"/proc/{pid}/stat") as f:
            fields = f.read().rsplit(")", 1)[1].split()
    except OSError:
        return None
    return fields[0], (int(fields[11]) + int(fields[12])) / TICKS


def status_of(wait_status: int) -> int:
    """Exit status in the shell's encoding: the exit code, or 128 + signal number."""
    if os.WIFSIGNALED(wait_status):
        return 128 + os.WTERMSIG(wait_status)
    return os.WEXITSTATUS(wait_status)


class Transcript:
    """Splits each direction's bytes into lines and records them in the order they arrive."""

    def __init__(self, path: str | None, live: bool) -> None:
        self.file = open(path, "w", encoding="utf-8", errors="replace") if path else None
        self.live = live
        color = live and sys.stderr.isatty() and not os.environ.get("NO_COLOR")
        self.colors = {">": "\033[36m", "<": "\033[33m"} if color else {}
        self.pending = {">": b"", "<": b""}

    def add(self, mark: str, data: bytes) -> None:
        *lines, self.pending[mark] = (self.pending[mark] + data).split(b"\n")
        for line in lines:
            self.write(mark, line.decode(errors="replace"))

    def close(self) -> None:
        for mark, rest in self.pending.items():
            if rest:
                self.write(mark, rest.decode(errors="replace") + "  (no newline)")
        if self.file:
            self.file.close()

    def write(self, mark: str, line: str) -> None:
        text = f"{mark} {line}"
        if self.file:
            self.file.write(text + "\n")
        if self.live:
            color = self.colors.get(mark, "")
            sys.stderr.write(f"{color}{text}{chr(27) + '[0m' if color else ''}\n")
            sys.stderr.flush()


class Pipe:
    """Passes bytes from one program's stdout to the other's stdin without blocking."""

    def __init__(self, src: int, dst: int, mark: str) -> None:
        self.src, self.dst, self.mark = src, dst, mark
        self.buffer = b""
        os.set_blocking(src, False)
        os.set_blocking(dst, False)

    def flush(self) -> None:
        if self.dst < 0:
            self.buffer = b""
            return
        try:
            while self.buffer:
                self.buffer = self.buffer[os.write(self.dst, self.buffer) :]
        except BlockingIOError:
            pass
        except BrokenPipeError:
            self.close_dst()

    def close_dst(self) -> None:
        if self.dst >= 0:
            os.close(self.dst)
            self.dst = -1
        self.buffer = b""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--kill", type=float, required=True)
    parser.add_argument("--limit", type=float, required=True)
    parser.add_argument("--transcript")
    parser.add_argument("--solution-err")
    parser.add_argument("--interactor-err")
    parser.add_argument("solution")
    parser.add_argument("interactor")
    parser.add_argument("input")
    parser.add_argument("answer", nargs="?")
    args = parser.parse_args()

    def stderr_for(path: str | None):
        return None if args.live or not path else open(path, "wb")

    sol_in, to_sol = os.pipe()
    from_sol, sol_out = os.pipe()
    inter_in, to_inter = os.pipe()
    from_inter, inter_out = os.pipe()
    sol = subprocess.Popen([args.solution], stdin=sol_in, stdout=sol_out, stderr=stderr_for(args.solution_err),
                           env=dict(os.environ, CP_INTERACTIVE="1"))
    inter_args = [args.interactor, args.input] + ([args.answer] if args.answer else [])
    inter = subprocess.Popen(inter_args, stdin=inter_in, stdout=inter_out, stderr=stderr_for(args.interactor_err))
    for fd in (sol_in, sol_out, inter_in, inter_out):
        os.close(fd)

    transcript = Transcript(args.transcript, args.live)
    pipes = [Pipe(from_sol, to_inter, ">"), Pipe(from_inter, to_sol, "<")]
    selector = selectors.DefaultSelector()
    for pipe in pipes:
        selector.register(pipe.src, selectors.EVENT_READ, pipe)

    sol_status = inter_status = None
    sol_cpu, sol_rss = 0.0, 0
    killed = None  # "timeout", "deadlock" or "interactor"
    timeout_detail = ""
    start = last_traffic = time.monotonic()

    # Popen.send_signal would reap the process, losing its resource usage, so this uses os.kill.
    def kill(proc: subprocess.Popen, status: int | None) -> None:
        if status is None:
            try:
                os.kill(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    try:
        while True:
            for key, _ in selector.select(0.05):
                pipe = key.data
                try:
                    data = os.read(pipe.src, 65536)
                except BlockingIOError:
                    continue
                if not data:
                    selector.unregister(pipe.src)
                    os.close(pipe.src)
                    pipe.flush()
                    pipe.close_dst()
                    continue
                last_traffic = time.monotonic()
                transcript.add(pipe.mark, data)
                pipe.buffer += data
                pipe.flush()
            for pipe in pipes:
                pipe.flush()

            if sol_status is None:
                pid, status, usage = os.wait4(sol.pid, os.WNOHANG)
                if pid:
                    sol_status = sol.returncode = status_of(status)
                    sol_cpu, sol_rss = usage.ru_utime + usage.ru_stime, usage.ru_maxrss
            if inter_status is None:
                pid, status, _ = os.wait4(inter.pid, os.WNOHANG)
                if pid:
                    inter_status = inter.returncode = status_of(status)
            if sol_status is not None and inter_status is not None:
                break

            now = time.monotonic()
            # A judge stops the solution as soon as the interactor rejects it.
            if inter_status is not None and inter_status != 0 and killed is None:
                killed = "interactor"
                kill(sol, sol_status)
            if killed is None and now - start >= args.kill:
                killed = "timeout"
                state = proc_stat(inter.pid)
                if inter_status is None and state and state[0] == "R":
                    timeout_detail = "the interactor was still running"
            elif killed is None and now - last_traffic >= DEADLOCK_SECONDS:
                states = [proc_stat(p.pid) if s is None else None
                          for p, s in ((sol, sol_status), (inter, inter_status))]
                if states[0] and states[0][0] == "S" and (inter_status is not None or (states[1] and states[1][0] == "S")):
                    killed = "deadlock"
            if killed in ("timeout", "deadlock"):
                if sol_status is None and (state := proc_stat(sol.pid)):
                    sol_cpu = state[1]
                kill(sol, sol_status)
                kill(inter, inter_status)
    finally:
        for proc in (sol, inter):
            if proc.returncode is None:
                kill(proc, None)
                proc.wait()
        transcript.close()

    elapsed = f"{sol_cpu:.3f}"
    sol_killed = killed in ("timeout", "deadlock") or (killed == "interactor" and sol_status == 128 + signal.SIGKILL)
    status = 124 if killed in ("timeout", "deadlock") else sol_status

    if inter_status not in (0, 1) and killed not in ("timeout", "deadlock"):
        verdict, detail = "FAIL", "interactor error" if inter_status == 2 else f"interactor {describe(inter_status)}"
    elif killed == "timeout" and timeout_detail:
        verdict, detail = "FAIL", timeout_detail
    elif killed in ("timeout", "deadlock"):
        if sol_cpu > args.limit:
            verdict, detail = "TLE", f"killed after {args.kill:g}s"
        elif killed == "deadlock":
            verdict, detail = "ILE", "both sides waiting for input; missing flush?"
        else:
            verdict, detail = "ILE", f"waiting for input after {args.kill:g}s"
    elif sol_status != 0 and not sol_killed:
        verdict, detail = "RE", describe(sol_status)
    elif inter_status == 1:
        verdict, detail = "WA", ""
    elif sol_cpu > args.limit:
        verdict, detail = "TLE", "answer accepted"
    else:
        verdict, detail = "PASS", ""
    print(verdict, status, elapsed, sol_rss, detail)


def describe(status: int) -> str:
    if status > 128:
        try:
            return f"signal {signal.Signals(status - 128).name.removeprefix('SIG')}"
        except ValueError:
            return f"signal {status - 128}"
    return f"exit code {status}"


if __name__ == "__main__":
    main()
