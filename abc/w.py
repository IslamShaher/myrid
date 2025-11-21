import pandas as pd
import numpy as np

INPUT_FILE = "roi_input.csv"          # <-- your ROI CSV file
OUTPUT_FILE = "stability_results.csv" # <-- final output


def sum_of_drops(row):
    """Sum all negative quarterly returns."""
    vals = [v for v in row if v < 0]
    return round(sum(vals), 1) if vals else 0.0


def max_drop(row):
    """Return the worst (most negative) quarterly return."""
    negative_vals = [v for v in row if v < 0]
    return round(min(negative_vals), 1) if negative_vals else 0.0


def main():
    print("\nLoading ROI data from:", INPUT_FILE)
    df = pd.read_csv(INPUT_FILE)

    # Extract quarter columns (all except Ticker)
    quarter_cols = [c for c in df.columns if c != "Ticker"]

    # Calculate metrics
    df["Sum_of_Drops"] = df[quarter_cols].apply(lambda r: sum_of_drops(r.values), axis=1)
    df["Max_Drop"] = df[quarter_cols].apply(lambda r: max_drop(r.values), axis=1)

    # Sort by lowest drop (most stable)
    ranked_sum = df.sort_values(by="Sum_of_Drops", ascending=True)

    # Sort by least severe single drop
    ranked_max = df.sort_values(by="Max_Drop", ascending=True)

    print("\n=== Ranking by SUM OF DROPS (most stable first) ===\n")
    print(ranked_sum[["Ticker", "Sum_of_Drops"]].to_string(index=False))

    print("\n=== Ranking by MAX SINGLE DROP (least severe first) ===\n")
    print(ranked_max[["Ticker", "Max_Drop"]].to_string(index=False))

    # Save combined results
    df.to_csv(OUTPUT_FILE, index=False)
    print("\nSaved combined results to:", OUTPUT_FILE)


if __name__ == "__main__":
    main()

