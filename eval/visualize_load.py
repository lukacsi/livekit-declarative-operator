import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

# --- CONFIGURATION ---
INPUT_FILE = "case_8/load.txt"  # Paste your terminal output into this file
OUTPUT_FILE = "load_test_results.pdf"

def parse_data():
    data = []
    # Regex to capture: ID, Bitrate, Unit, Loss Count, Loss %
    # Example: │ Sub 0  │ 6/50     │ 3.2mbps                  │ 886 (0.107%)     │ -      │
    regex = r"│\s+Sub\s+(\d+)\s+│\s+\S+\s+│\s+([\d\.]+)(mbps|kbps)\s+│\s+(\d+)\s+\(([\d\.]+)%\)\s+│"
    
    try:
        with open(INPUT_FILE, 'r') as f:
            content = f.read()
            
        # We only care about the "Subscriber summaries" table
        if "Subscriber summaries:" in content:
            content = content.split("Subscriber summaries:")[1]
            
        for line in content.split('\n'):
            match = re.search(regex, line)
            if match:
                sub_id = int(match.group(1))
                val = float(match.group(2))
                unit = match.group(3)
                loss_pct = float(match.group(5))
                
                # Normalize everything to Mbps
                bitrate_mbps = val if unit == "mbps" else val / 1000.0
                
                data.append({
                    "Subscriber": sub_id,
                    "Bitrate (Mbps)": bitrate_mbps,
                    "Packet Loss (%)": loss_pct
                })
    except FileNotFoundError:
        print(f"❌ Error: {INPUT_FILE} not found. Paste your terminal output there first.")
        return pd.DataFrame()

    return pd.DataFrame(data).sort_values("Subscriber")

def generate_graph():
    df = parse_data()
    if df.empty: return

    # Setup Plot
    fig, ax1 = plt.subplots(figsize=(12, 6))
    sns.set_style("whitegrid")
    
    color_bitrate = "#4a90e2" # Soft Blue
    color_loss = "#e74c3c"    # Red

    # 1. Bar Chart (Bitrate)
    sns.barplot(data=df, x="Subscriber", y="Bitrate (Mbps)", ax=ax1, 
                color=color_bitrate, alpha=0.6, label="Bitrate")
    ax1.set_ylabel("Bitrate (Mbps)", color=color_bitrate, fontsize=12, fontweight='bold')
    ax1.tick_params(axis='y', labelcolor=color_bitrate)
    ax1.set_xlabel("Subscriber ID", fontsize=12)
    
    # Hide every 2nd x-label to prevent crowding
    for ind, label in enumerate(ax1.get_xticklabels()):
        if ind % 2 != 0: label.set_visible(False)

    # 2. Line Chart (Packet Loss) - Twin Axis
    ax2 = ax1.twinx()
    # Align line with bars using index
    sns.lineplot(data=df, x=df.reset_index().index, y="Packet Loss (%)", ax=ax2, 
                 color=color_loss, linewidth=2, marker="o", markersize=4 )
#    ax2.set_ylabel("Packet Loss (%)", color=color_loss, fontsize=12, fontweight='bold')
    ax2.tick_params(axis='y', labelcolor=color_loss)
    
    # Set reasonable limit (e.g. 1% max) so small loss is visible but doesn't skew
    max_loss = df["Packet Loss (%)"].max()
    ax2.set_ylim(0, max(max_loss * 1.5, 0.5))

    # Custom Legend
    legend_elements = [
        Patch(facecolor=color_bitrate, alpha=0.6, label='Bitrate (Mbps)'),
        Line2D([0], [0], color=color_loss, lw=2, marker='o', label='Packet Loss (%)')
    ]
    ax1.legend(handles=legend_elements, loc='upper left', frameon=True)

    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, format="pdf")
    print(f"✅ Graph saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    generate_graph()
