import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# --- CONFIGURATION ---
INPUT_FILE = "case_8/hpa_metrics.csv"
OUTPUT_FILE = "full_stack_scaling.pdf"

def generate_graph():
    try:
        df = pd.read_csv(INPUT_FILE)
    except FileNotFoundError:
        print(f"❌ Error: {INPUT_FILE} not found.")
        return

    # Convert Timestamp to Minutes for cleaner X-axis
    df['Time_Min'] = df['Timestamp'] / 60.0

    # Setup the plot with 2 subplots sharing the X-axis
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True)
    sns.set_style("whitegrid")
    
    # Define academic colors
    c_lk = '#1f77b4'  # Blue for LiveKit
    c_st = '#ff7f0e'  # Orange for STUNner

    # --- SUBPLOT 1: CPU Utilization ---
    # LiveKit CPU
    sns.lineplot(data=df, x='Time_Min', y='Livekit_CPU_Percent', ax=ax1, 
                 color=c_lk, label='LiveKit Server', linewidth=2)
    # STUNner CPU
    sns.lineplot(data=df, x='Time_Min', y='Stunner_CPU_Percent', ax=ax1, 
                 color=c_st, label='STUNner Gateway', linewidth=2, linestyle='--')
    
    # Add HPA Threshold line
    ax1.axhline(80, color='red', linestyle=':', alpha=0.8, linewidth=1.5, label="HPA Target (80%)")
    
    ax1.set_ylabel("CPU Utilization (%)", fontsize=12, fontweight='bold')
    ax1.legend(loc="upper right", frameon=True)
    ax1.grid(True, linestyle='--', alpha=0.5)
    
    # Optimize Y-axis to show the spike clearly
    ax1.set_ylim(0, max(df['Livekit_CPU_Percent'].max(), df['Stunner_CPU_Percent'].max()) * 1.1)

    # --- SUBPLOT 2: Replica Count ---
    # LiveKit Replicas
    sns.lineplot(data=df, x='Time_Min', y='Livekit_Replicas', ax=ax2, 
                 color=c_lk, label='LiveKit Server', linewidth=2.5, drawstyle='steps-post')
    # STUNner Replicas
    sns.lineplot(data=df, x='Time_Min', y='Stunner_Replicas', ax=ax2, 
                 color=c_st, label='STUNner Gateway', linewidth=2.5, drawstyle='steps-post', linestyle='--')
    
    ax2.set_ylabel("Replica Count", fontsize=12, fontweight='bold')
    ax2.set_xlabel("Time (Minutes)", fontsize=12, fontweight='bold')
    
    # Set Integer Ticks for Replicas
    max_replicas = max(df['Livekit_Replicas'].max(), df['Stunner_Replicas'].max())
    ax2.set_ylim(0, max_replicas + 2)
    ax2.set_yticks(range(0, int(max_replicas) + 3))
    
    ax2.legend(loc="lower right", frameon=True)
    ax2.grid(True, linestyle='--', alpha=0.5)

    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, format="pdf", bbox_inches="tight")
    print(f"✅ Graph saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    generate_graph()
