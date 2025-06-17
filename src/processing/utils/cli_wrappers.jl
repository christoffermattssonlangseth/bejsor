function estimate_gene_structure_embedding(df_spatial::DataFrame, gene_names::Vector{String}, confidence::Vector{Float64}=df_spatial.confidence)
    adj_list = build_molecule_graph(df_spatial, filter=false)
    cor_mat = pairwise_gene_spatial_cor(df_spatial.gene, confidence, adj_list);
    cor_vals = vec(cor_mat)
    min_cor = quantile(cor_vals[cor_vals .> 0], 0.001) ./ 5;
    max_cor = quantile(cor_vals, 0.99);
    p_dists = 1 .- max.(min.(cor_mat, max_cor), min_cor) ./ max_cor;
    p_dists[diagind(p_dists)] .= 0.0;

    embedding = UMAP.umap(p_dists, 2; metric=:precomputed, spread=1.0, min_dist=0.1, n_epochs=5000, n_neighbors=max(min(15, length(gene_names) ÷ 2), 2));
    marker_sizes = log.(count_array(df_spatial.gene));

    return DataFrame(Dict(:x => embedding[1,:], :y => embedding[2,:], :gene => Symbol.(gene_names), :size => marker_sizes));
end

function run_segmentation(
        df_spatial::DataFrame, gene_names::Vector{String}, opts::SegmentationOptions;
        plot_opts::PlottingOptions, min_molecules_per_cell::Int, plot::Bool, save_polygons::Bool,
        run_id::String
    )
    # Region-based segmentations

    comp_segs, comp_genes = nothing, Vector{Int}[]
    adj_list = build_molecule_graph(df_spatial; use_local_gene_similarities=false, adjacency_type=:auto)
    if opts.nuclei_genes != ""
        comp_segs, comp_genes, df_spatial[!, :compartment] = estimate_molecule_compartments(
            df_spatial, gene_names; nuclei_genes=opts.nuclei_genes, cyto_genes=opts.cyto_genes, scale=opts.scale
        )
        df_spatial[!, :nuclei_probs] = 1 .- comp_segs.assignment_probs[2,:];

        adjust_mrf_with_compartments!(
            adj_list, comp_segs.assignment_probs[1,:], comp_segs.assignment_probs[2,:]
        );
    end

    mol_clusts = nothing
    if opts.n_clusters > 1
        mol_clusts = estimate_molecule_clusters(df_spatial, opts.n_clusters)
        df_spatial[!, :cluster] = mol_clusts.assignment;
    end

    # Cell segmentation

    n_cells_init = something(
        opts.n_cells_init,
        default_param_value(:n_cells_init, min_molecules_per_cell, n_molecules=size(df_spatial, 1))
    )

    bm_data = initialize_bmm_data(
        df_spatial; scale=opts.scale, scale_std=opts.scale_std, n_cells_init,
        prior_seg_confidence=opts.prior_segmentation_confidence, min_molecules_per_cell,
        adj_list, na_genes=Vector{Int}(vcat(comp_genes...))
    );

    @info "Using $(size(position_data(bm_data), 1))D coordinates"

    history_depth = round(Int, opts.iters * 0.1)
    bm_data = bmm!(
        bm_data; min_molecules_per_cell, n_iters=opts.iters, assignment_history_depth=history_depth
    );

    @info "Processing complete."

    # Extract results

    segmented_df, cell_stat_df, cm = get_segmentation_results(bm_data, gene_names; run_id)

    #@info "Estimating local colors"
    #gene_colors = gene_composition_colors(
    #    bm_data.x, plot_opts.gene_composition_neigborhood; method=Symbol(plot_opts.ncv_method)
    #)
    #segmented_df[!, :ncv_color] = "#" .* Colors.hex.(gene_colors)

    poly_joined, polygons = nothing, nothing
    if save_polygons || plot
        poly_joined, polygons = boundary_polygons_auto(
            position_data(bm_data), bm_data.assignment; estimate_per_z=save_polygons, cell_names=cell_stat_df.cell
        )
    end

    return (
        segmented_df, bm_data.tracer, mol_clusts, comp_segs, poly_joined,
        cell_stat_df, cm, polygons
    )
end