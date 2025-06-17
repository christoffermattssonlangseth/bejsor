# Bejsor
<p align="center">
  <img src="assets/bejsor_logo.png" alt="Bejsor logo" width="200"/>
</p>
⚠️ **Disclaimer:** This is *not* the official Baysor repository. This is a modified fork, humorously named **Bejsor**, which includes a **stupid workaround** to reduce excessive RAM usage when running Baysor on high-transcript-count datasets (e.g., Xenium 5K+ panels).

It is meant for **experimental use only** and should not be considered a reliable alternative to the [official Baysor repository](https://github.com/kharchenkolab/Baysor). Use at your own risk.

---

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://kharchenkolab.github.io/Baysor/dev)

## What is Bejsor?

**Bay**esian **E**xperimental **J**anky **S**egmentation **o**f spatial t**r**anscriptomics data

This is a lightly modified version of [Baysor](https://github.com/kharchenkolab/Baysor) with:

- The **local NCV color estimation step disabled** to mitigate RAM issues
- Minor tweaks for CLI usability and config overrides
- Everything else untouched from upstream

The name *Bejsor* reflects that this is **not production-ready**. It’s a playground version to try out tweaks that may (or may not) work on large datasets.

---

## ⚠️ NOT the Official Baysor

If you're looking for a maintained and production-ready tool for segmentation, you should use the official Baysor:

👉 https://github.com/kharchenkolab/Baysor  
👉 https://kharchenkolab.github.io/Baysor/

---

## Quick Install

Clone and use locally:

```bash
git clone https://github.com/YOUR_USERNAME/bejsor.git
cd bejsor
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build()'

```

## Citation 
Petukhov V, Xu RJ, Soldatov RA, Cadinu P, Khodosevich K, Moffitt JR & Kharchenko PV.
Cell segmentation in imaging-based spatial transcriptomics.
Nat Biotechnol (2021). https://doi.org/10.1038/s41587-021-01044-w