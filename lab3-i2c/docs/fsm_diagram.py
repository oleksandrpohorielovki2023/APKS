"""Draw the FSM diagrams of i2c_master (Tx) and i2c_slave (Rx) -> fsm_master.png, fsm_slave.png."""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyArrowPatch

OUT = Path(__file__).parent
R = 0.72


def draw(states, edges, title, path, size):
    fig, ax = plt.subplots(figsize=size, dpi=150)
    ax.set_aspect("equal")
    ax.axis("off")
    for name, (x, y) in states.items():
        ax.add_patch(Circle((x, y), R, fc="#eef3fb", ec="#1f3b73", lw=1.6))
        ax.text(x, y, name, ha="center", va="center", fontsize=7.5, fontweight="bold", color="#1f3b73")
    for a, b, label, rad, offset in edges:
        (x1, y1), (x2, y2) = states[a], states[b]
        if a == b:   # self loop above the state
            ax.add_patch(FancyArrowPatch((x1 - 0.3, y1 + 0.45), (x1 + 0.3, y1 + 0.45),
                                         connectionstyle="arc3,rad=-1.6", arrowstyle="-|>",
                                         mutation_scale=12, lw=1.1, color="#444"))
            ax.text(x1, y1 + 1.15, label, ha="center", va="bottom", fontsize=7.5)
            continue
        ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), connectionstyle=f"arc3,rad={rad}",
                                     arrowstyle="-|>", mutation_scale=13, lw=1.2, color="#444",
                                     shrinkA=30, shrinkB=30))
        mx, my = (x1 + x2) / 2 + offset[0], (y1 + y2) / 2 + offset[1]
        ax.text(mx, my, label, ha="center", va="center", fontsize=7.5,
                bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none"))
    xs = [p[0] for p in states.values()]
    ys = [p[1] for p in states.values()]
    ax.set_xlim(min(xs) - 1.2, max(xs) + 1.2)
    ax.set_ylim(min(ys) - 3.2, max(ys) + 1.9)
    ax.set_title(title, fontsize=11)
    fig.savefig(path, bbox_inches="tight", facecolor="white")
    plt.close(fig)


master_states = {
    "IDLE": (0, 0), "START": (2.4, 0), "ADDR": (4.8, 0), "ADDR_ACK": (7.2, 0),
    "WR": (9.6, 2.2), "WR_ACK": (12.0, 2.2), "RD": (9.6, -2.2), "RD_NACK": (12.0, -2.2),
    "STOP": (14.4, 0),
}
master_edges = [
    ("IDLE", "IDLE", "start = 0", 0, (0, 0)),
    ("IDLE", "START", "start = 1", 0, (0, 0.3)),
    ("START", "ADDR", "SDA 1→0\nпри SCL = 1", 0, (0, 0.45)),
    ("ADDR", "ADDR", "біт < 8", 0, (0, 0)),
    ("ADDR", "ADDR_ACK", "8 біт\n(адреса+R/W)", 0, (0, 0.45)),
    ("ADDR_ACK", "WR", "ACK, R/W = 0", 0, (-0.6, 0.35)),
    ("ADDR_ACK", "RD", "ACK, R/W = 1", 0, (-0.6, -0.35)),
    ("ADDR_ACK", "STOP", "NACK\n(ack_err)", 0, (0, -0.35)),
    ("WR", "WR", "біт < 8", 0, (0, 0)),
    ("WR", "WR_ACK", "8 біт", 0, (0, 0.3)),
    ("WR_ACK", "STOP", "ACK / NACK", 0, (0.5, 0.35)),
    ("RD", "RD", "біт < 8", 0, (0, 0)),
    ("RD", "RD_NACK", "8 біт", 0, (0, 0.3)),
    ("RD_NACK", "STOP", "NACK майстра", 0, (0.6, -0.35)),
    ("STOP", "IDLE", "SDA 0→1 при SCL = 1 (STOP), done = 1", -0.5, (0, -3.35)),
]
draw(master_states, master_edges, "FSM передавача i2c_master (Tx)", OUT / "fsm_master.png", (14, 6.2))

slave_states = {
    "IDLE": (0, 0), "ADDR": (2.6, 0), "ADDR_ACK": (5.2, 0),
    "RX": (7.8, 2.2), "RX_ACK": (10.4, 2.2), "TX": (7.8, -2.2), "TX_ACK": (10.4, -2.2),
}
slave_edges = [
    ("IDLE", "ADDR", "START", 0, (0, 0.3)),
    ("ADDR", "ADDR", "фронт SCL:\nприйом біта", 0, (0, 0)),
    ("ADDR", "IDLE", "чужа адреса", -0.6, (0, -1.0)),
    ("ADDR", "ADDR_ACK", "8 біт, своя\nадреса → ACK", 0, (0, 0.45)),
    ("ADDR_ACK", "RX", "R/W = 0", 0, (-0.5, 0.35)),
    ("ADDR_ACK", "TX", "R/W = 1", 0, (-0.5, -0.35)),
    ("RX", "RX_ACK", "8 біт → rx_data,\nrx_valid, ACK", 0, (0, 0.5)),
    ("RX_ACK", "RX", "наступний байт", -0.5, (0, -0.85)),
    ("TX", "TX_ACK", "8 біт видано", 0, (0, 0.3)),
    ("TX_ACK", "TX", "ACK майстра", -0.5, (0, -0.85)),
    ("TX_ACK", "IDLE", "NACK майстра", -0.35, (0.6, -1.75)),
]
draw(slave_states, slave_edges, "FSM приймача i2c_slave (Rx); STOP з будь-якого стану → IDLE",
     OUT / "fsm_slave.png", (12, 6.2))
print("ok")
