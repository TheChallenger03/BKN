import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Configurazione stile
sns.set_theme(style="whitegrid")
plt.rcParams['figure.figsize'] = (10, 6)
plt.rcParams['font.size'] = 12

def plot_dataset_size_performance():
    """Grafico 1: Performance vs Dataset Size"""
    df = pd.read_csv('results/benchmark_dataset_size.csv')
    
    fig, ax = plt.subplots()
    
    ax.plot(df['Dataset Size'], df['Simple SELECT (ms)'], 
            marker='o', label='Simple SELECT', linewidth=2)
    ax.plot(df['Dataset Size'], df['Aggregation (ms)'], 
            marker='s', label='Aggregation', linewidth=2)
    ax.plot(df['Dataset Size'], df['Geospatial (ms)'], 
            marker='^', label='Geospatial Query', linewidth=2)
    
    ax.set_xlabel('Dataset Size (number of records)')
    ax.set_ylabel('Execution Time (ms)')
    ax.set_title('Query Performance vs Dataset Size')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('results/graph_dataset_size.png', dpi=300)
    print('✅ Saved: graph_dataset_size.png')

def plot_query_complexity():
    """Grafico 2: Query Complexity Comparison"""
    df = pd.read_csv('results/benchmark_query_complexity.csv')
    
    fig, ax = plt.subplots()
    
    colors = sns.color_palette("husl", len(df))
    bars = ax.barh(df['Query Type'], df['Execution Time (ms)'], color=colors)
    
    # Aggiungi etichette complessità
    for i, (bar, complexity) in enumerate(zip(bars, df['Complexity'])):
        width = bar.get_width()
        ax.text(width + 1, bar.get_y() + bar.get_height()/2, 
                f'{complexity}', 
                ha='left', va='center', fontsize=10)
    
    ax.set_xlabel('Execution Time (ms)')
    ax.set_title('Query Complexity Analysis (10K records)')
    ax.grid(axis='x', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('results/graph_query_complexity.png', dpi=300)
    print('✅ Saved: graph_query_complexity.png')

def plot_batch_insert_scalability():
    """Grafico 3: Batch Insert Scalability"""
    df = pd.read_csv('results/benchmark_batch_insert.csv')
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Subplot 1: Tempo totale
    ax1.plot(df['Record Count'], df['Total Time (ms)'], 
             marker='o', linewidth=2, color='steelblue')
    ax1.set_xlabel('Record Count')
    ax1.set_ylabel('Total Time (ms)')
    ax1.set_title('Batch Insert - Total Time')
    ax1.grid(True, alpha=0.3)
    
    # Subplot 2: Records per second
    ax2.plot(df['Record Count'], df['Records per Second'], 
             marker='s', linewidth=2, color='coral')
    ax2.set_xlabel('Record Count')
    ax2.set_ylabel('Records per Second')
    ax2.set_title('Batch Insert - Throughput')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('results/graph_batch_insert.png', dpi=300)
    print('✅ Saved: graph_batch_insert.png')

def plot_geospatial_accuracy():
    """Grafico 4: Geospatial Query Accuracy"""
    df = pd.read_csv('results/benchmark_geospatial_accuracy.csv')
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Subplot 1: Locations found
    ax1.bar(df['Radius (km)'].astype(str), df['Locations Found'], 
            color='mediumseagreen', alpha=0.7)
    ax1.set_xlabel('Search Radius (km)')
    ax1.set_ylabel('Locations Found')
    ax1.set_title('Geospatial Search - Locations Found')
    ax1.grid(axis='y', alpha=0.3)
    
    # Subplot 2: Execution time
    ax2.plot(df['Radius (km)'], df['Execution Time (ms)'], 
             marker='o', linewidth=2, color='tomato')
    ax2.set_xlabel('Search Radius (km)')
    ax2.set_ylabel('Execution Time (ms)')
    ax2.set_title('Geospatial Search - Performance')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('results/graph_geospatial.png', dpi=300)
    print('✅ Saved: graph_geospatial.png')

def generate_summary_table():
    """Tabella riassuntiva per LaTeX"""
    df_size = pd.read_csv('results/benchmark_dataset_size.csv')
    
    # Calcola speedup
    baseline = df_size.iloc[0]
    df_size['Speedup Simple'] = baseline['Simple SELECT (ms)'] / df_size['Simple SELECT (ms)']
    
    # Genera LaTeX
    latex = df_size.to_latex(index=False, float_format="%.2f")
    
    with open('results/table_performance.tex', 'w') as f:
        f.write(latex)
    
    print('✅ Saved: table_performance.tex')

if __name__ == '__main__':
    print('📊 Generating thesis graphs...\n')
    
    plot_dataset_size_performance()
    plot_query_complexity()
    plot_batch_insert_scalability()
    plot_geospatial_accuracy()
    generate_summary_table()
    
    print('\n✅ All graphs generated successfully!')
    print('📁 Check: test/performance/results/')