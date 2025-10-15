import os
import networkx as nx
import matplotlib.pyplot as plt

def visualize_graph(gph_filepath, output_filepath):
    """
    Reads a graph from a .gph file, visualizes it using NetworkX,
    and saves the plot to a file.
    """

    G = nx.DiGraph()

    with open(gph_filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            parts = line.split(',')
            if len(parts) == 2:
                parent, child = parts[0], parts[1]
                G.add_edge(parent, child)

    if G.number_of_nodes() == 0:
        print(f"Warning: No nodes found in {gph_filepath}. Skipping.")
        return

    plt.figure(figsize=(12, 12)) # Default size
    node_size = 2000
    font_size = 8
    arrow_size = 20
    
    graph_name = os.path.basename(gph_filepath).replace('.gph', '')
    
    if 'medium' in graph_name:
        plt.figure(figsize=(20, 20))
        node_size = 2500
        font_size = 9
    elif 'large' in graph_name:
        plt.figure(figsize=(35, 35))
        node_size = 1500
        font_size = 7
        arrow_size = 15

    try:
        pos = nx.kamada_kawai_layout(G)
    except nx.NetworkXError:
        pos = nx.spring_layout(G, seed=42)

    nx.draw_networkx_nodes(G, pos, node_color='skyblue', node_size=node_size)
    nx.draw_networkx_edges(G, pos, node_size=node_size, arrowstyle='->', 
                           arrowsize=arrow_size, edge_color='gray')
    nx.draw_networkx_labels(G, pos, font_size=font_size, font_family='sans-serif')

    plt.title(f"Learned Bayesian Network Structure for '{graph_name}'", size=20)
    plt.axis('off') # Hide the axes
    
    plt.savefig(output_filepath, bbox_inches='tight', dpi=150)
    plt.close() # Close the figure to free up memory


def main():
    """
    Main function to find and visualize all .gph files.
    """
    input_dir = "submission_graphs"
    output_dir = "visualizations"

    os.makedirs(output_dir, exist_ok=True)
    
    files_to_visualize = ["small.gph", "medium.gph", "large.gph"]

    for filename in files_to_visualize:
        gph_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename.replace('.gph', '.pdf'))

        if os.path.exists(gph_path):
            visualize_graph(gph_path, output_path)
        else:
            print(f"Error: Could not find file {gph_path}")



if __name__ == "__main__":
    main()