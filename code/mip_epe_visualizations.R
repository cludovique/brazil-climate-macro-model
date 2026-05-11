# =============================================================================
# MIP-EPE ENERGY 2018 — VISUALIZATIONS
# Run AFTER mip_epe_replication.R
#
# Fixes applied vs previous version:
#   1. occ alias added (replication uses ocupacoes, viz used occ)
#   2. scale_fill_manual updated to 7-group names
#   3. sector_group factor levels updated to 7-group names
#   4. plot_shock_comparison collapses 7 groups to 4 for NT comparison
#   5. PAL updated with all 7 group colors
#   6. Rasmussen: fossil=red, renewable=teal (matches NT image style)
#   7. p3_mult: fossil=red, renewable=teal
# =============================================================================


# =============================================================================
# 0. PACKAGES
# =============================================================================

vis_pkgs <- c("ggplot2", "dplyr", "tidyr", "scales",
              "ggrepel", "patchwork", "forcats")
for (p in vis_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}


# =============================================================================
# ALIASES AND CONSTANTS
# =============================================================================

occ <- ocupacoes    # alias — replication script uses ocupacoes

caption_src <- "Source: MIP-EPE/FIPE 2018 (Anexo 2). Authors' calculations."


# =============================================================================
# COLOR PALETTE — 7 groups + auxiliaries
# =============================================================================

PAL <- list(
  agro      = "#3B6D11",   # green       — Agropecuaria
  extrativa = "#888780",   # gray        — Ind_Extrativa
  fossil    = "#E24B4A",   # red         — Energia_Fossil
  renovavel = "#1D9E75",   # teal        — Energia_Renov
  industria = "#378ADD",   # blue        — Ind_Transform
  infra     = "#534AB7",   # purple      — Infraestrutura
  servicos  = "#B4B2A9",   # light gray  — Servicos
  nt        = "#BA7517",   # amber       — NT reference bars
  neutral   = "#D3D1C7"    # very light  — below average
)

grupo_colors <- c(
  Agropecuaria   = PAL$agro,
  Ind_Extrativa  = PAL$extrativa,
  Energia_Fossil = PAL$fossil,
  Energia_Renov  = PAL$renovavel,
  Ind_Transform  = PAL$industria,
  Infraestrutura = PAL$infra,
  Servicos       = PAL$servicos
)

grupo_levels <- c("Agropecuaria","Ind_Extrativa","Energia_Fossil",
                  "Energia_Renov","Ind_Transform","Infraestrutura","Servicos")


# =============================================================================
# THEME
# =============================================================================

theme_mip <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(color = "grey90", linewidth = 0.4),
      axis.line         = element_line(color = "grey70", linewidth = 0.4),
      axis.ticks        = element_line(color = "grey70", linewidth = 0.3),
      plot.title        = element_text(size = base_size + 1, face = "bold",
                                       margin = margin(b = 6)),
      plot.subtitle     = element_text(size = base_size - 1, color = "grey40",
                                       margin = margin(b = 10)),
      plot.caption      = element_text(size = base_size - 2,
                                       color = "grey50", hjust = 0),
      legend.position   = "bottom",
      legend.key.size   = unit(0.4, "cm"),
      strip.text        = element_text(face = "bold", size = base_size - 1)
    )
}


# =============================================================================
# RASMUSSEN LINKAGES
# =============================================================================

global_mean <- mean(L)
Uj   <- colMeans(L) / global_mean
Ui   <- rowMeans(L) / global_mean
mult <- colSums(L)

quadrant <- dplyr::case_when(
  Uj >= 1 & Ui >= 1 ~ "Key sector (Uj>=1, Ui>=1)",
  Uj >= 1 & Ui <  1 ~ "Demand-driven (Uj>=1)",
  Uj <  1 & Ui >= 1 ~ "Supply-driven (Ui>=1)",
  TRUE               ~ "Independent"
)

energy_labels <- c(
  S05 = "Ext. Petroleo",    S19 = "Der. Petroleo",
  S20 = "Biodiesel",        S21 = "Coquerias",
  S22 = "Etanol",           S40 = "Ger. Centralizada",
  S41 = "Ger. Distribuida", S42 = "Transmissao",
  S43 = "Gas Natural"
)

df_linkages <- data.frame(
  cod       = setores$cod,
  nome      = setores$nome,
  Uj        = Uj,
  Ui        = Ui,
  mult      = mult,
  quadrant  = quadrant,
  is_energy = setores$cod %in% energy_sectors,
  is_fossil = setores$cod %in% fossil_sectors,
  stringsAsFactors = FALSE
)
df_linkages$label <- ifelse(df_linkages$is_energy,
                             energy_labels[df_linkages$cod], "")


# =============================================================================
# CHART 1 — BASELINE OVERVIEW
# =============================================================================

df_groups <- do.call(rbind, lapply(names(grupos), function(g) {
  idx <- which(setores$cod %in% grupos[[g]])
  data.frame(
    grupo       = g,
    va_base     = sum(va_pib[idx]) / 1e3,
    emp_base    = sum(occ[idx])    / 1e3,
    output_base = sum(x[idx])      / 1e3,
    n_sectors   = length(idx),
    stringsAsFactors = FALSE
  )
}))

p_gdp_base <- df_groups |>
  mutate(grupo = fct_reorder(grupo, va_base)) |>
  ggplot(aes(va_base, grupo, fill = grupo)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(aes(label = paste0("R$", round(va_base, 0), "bi")),
            hjust = -0.1, size = 3.2) +
  scale_fill_manual(values = grupo_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(title = "GDP (Value Added) by sector group",
       subtitle = "Baseline 2018 — R$ billion",
       x = "R$ billion", y = NULL, caption = caption_src) +
  theme_mip()

p_emp_base <- df_groups |>
  mutate(grupo = fct_reorder(grupo, emp_base)) |>
  ggplot(aes(emp_base, grupo, fill = grupo)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(aes(label = paste0(round(emp_base / 1e3, 1), "M")),
            hjust = -0.1, size = 3.2) +
  scale_fill_manual(values = grupo_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(title = "Employment by sector group",
       subtitle = "Baseline 2018 — thousands of workers",
       x = "Thousand workers", y = NULL) +
  theme_mip() + theme(plot.caption = element_blank())

p1_combined <- p_gdp_base + p_emp_base +
  plot_annotation(
    title   = "1. Baseline production structure (2018)",
    caption = caption_src,
    theme   = theme(plot.title = element_text(size = 13, face = "bold"))
  )

ggsave("fig1_baseline_overview.png", p1_combined,
       width = 12, height = 5, dpi = 150)
message("Saved fig1_baseline_overview.png")


# =============================================================================
# CHART 2 — RASMUSSEN QUADRANT SCATTER
# =============================================================================

quad_shading <- data.frame(
  xmin = c(-Inf, 1, -Inf, 1),   xmax = c(1, Inf, 1, Inf),
  ymin = c(1, 1, -Inf, -Inf),   ymax = c(Inf, Inf, 1, 1),
  fill = c("A","B","C","D")
)

quad_labels <- data.frame(
  x = c(0.4, 2.8, 0.4, 2.8),
  y = c(1.38, 1.38, 0.60, 0.60),
  label = c("Demand-driven\n(Uj>1, Ui<1)", "Key sector\n(Uj>1, Ui>1)",
            "Independent\n(Uj<1, Ui<1)", "Supply-driven\n(Uj<1, Ui>1)")
)

p2_scatter <- ggplot() +
  geom_rect(data = quad_shading,
            aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, fill=fill),
            alpha = 0.04, show.legend = FALSE) +
  scale_fill_manual(values = c(A="#1D9E75",B="#534AB7",C="#888780",D="#378ADD")) +
  geom_vline(xintercept=1, color="grey50", linewidth=0.5, linetype="dashed") +
  geom_hline(yintercept=1, color="grey50", linewidth=0.5, linetype="dashed") +
  geom_point(data = filter(df_linkages, !is_energy),
             aes(Ui, Uj), color="grey40", size=1.8, alpha=0.6) +
  geom_point(data = filter(df_linkages, is_fossil),
             aes(Ui, Uj), color=PAL$fossil, size=3.5) +
  geom_point(data = filter(df_linkages, is_energy & !is_fossil),
             aes(Ui, Uj), color=PAL$renovavel, size=3.5) +
  geom_label_repel(
    data = filter(df_linkages, is_energy),
    aes(Ui, Uj, label=label,
        color = ifelse(is_fossil, PAL$fossil, PAL$renovavel)),
    fill="white", size=2.8, fontface="bold",
    box.padding=0.4, point.padding=0.3, label.size=0.2,
    segment.alpha=0.5, max.overlaps=20, show.legend=FALSE
  ) +
  scale_color_identity() +
  geom_text(data=quad_labels, aes(x, y, label=label),
            size=2.8, color="grey45", fontface="italic") +
  scale_x_continuous(limits=c(0,4.2), breaks=seq(0,4,0.5),
                     expand=expansion(mult=c(0,0.02))) +
  scale_y_continuous(limits=c(0.5,1.55), breaks=seq(0.5,1.5,0.1),
                     expand=expansion(mult=c(0,0.02))) +
  labs(title    = "2. Rasmussen linkages — energy sectors highlighted",
       subtitle = "Red = fossil energy | Teal = renewable energy. Dashed lines at economy average (1.0).",
       x = "Forward linkages (Ui)", y = "Backward linkages (Uj)",
       caption = caption_src) +
  theme_mip() + theme(legend.position="none")

ggsave("fig2_rasmussen_scatter.png", p2_scatter, width=9, height=6, dpi=150)
message("Saved fig2_rasmussen_scatter.png")


# =============================================================================
# CHART 3 — PRODUCTION MULTIPLIERS
# =============================================================================

mean_mult <- mean(colSums(L))

p3_mult <- df_linkages |>
  filter(is_energy) |>
  mutate(
    label_short = energy_labels[cod],
    label_short = fct_reorder(label_short, mult),
    grp_type    = ifelse(cod %in% fossil_sectors, "fossil", "renovavel")
  ) |>
  ggplot(aes(mult, label_short, fill = grp_type)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_vline(xintercept = mean_mult,
             linetype="dashed", color="grey50", linewidth=0.6) +
  geom_text(aes(label = round(mult, 3)), hjust=-0.15, size=3.2) +
  annotate("text", x=mean_mult+0.04, y=0.6,
           label=paste0("avg = ", round(mean_mult, 2)),
           hjust=0, size=2.8, color="grey50") +
  scale_fill_manual(values = c(fossil=PAL$fossil, renovavel=PAL$renovavel)) +
  scale_x_continuous(limits=c(0,4.3), expand=expansion(mult=c(0,0.12))) +
  labs(title    = "3. Production multipliers — energy sectors",
       subtitle = "Output per R$1 of final demand. Red = fossil | Teal = renewable.",
       x = "Production multiplier", y = NULL, caption = caption_src) +
  theme_mip()

ggsave("fig3_multipliers.png", p3_mult, width=8, height=4.5, dpi=150)
message("Saved fig3_multipliers.png")


# =============================================================================
# CHART 4 — LABOR HEATMAP
# =============================================================================

plot_labor_heatmap <- function() {
  
  labor_row_map <- c(Informal=115, Formal=116, PPI=117, Branca=118,
                     Homem=119, Mulher=120, Baixo_Med=121, Superior=122)
  
  heat_data <- do.call(rbind, lapply(names(grupos), function(g) {
    idx       <- which(setores$cod %in% grupos[[g]])
    total_emp <- sum(occ[idx])
    do.call(rbind, lapply(names(labor_row_map), function(lg) {
      vec <- suppressWarnings(
        as.numeric(as.character(unlist(sxs_raw[labor_row_map[lg], 4:(3+N)])))
      )
      vec[is.na(vec)] <- 0
      data.frame(sector_group=g, labor_group=lg,
                 share=sum(vec[idx])/total_emp*100,
                 stringsAsFactors=FALSE)
    }))
  }))
  
  heat_data <- heat_data |>
    mutate(
      labor_group = recode(labor_group,
                           Informal="Informal", Formal="Formal", PPI="PPI", Branca="White",
                           Homem="Men", Mulher="Women", Baixo_Med="Low/Mid educ.", Superior="Higher educ."
      ),
      labor_group  = factor(labor_group,
                            levels=c("Informal","Formal","PPI","White",
                                     "Men","Women","Low/Mid educ.","Higher educ.")),
      sector_group = factor(sector_group, levels = names(grupos))
    )
  
  p6 <- ggplot(heat_data, aes(labor_group, sector_group, fill=share)) +
    geom_tile(color="white", linewidth=0.5) +
    geom_text(aes(label=paste0(round(share,0),"%")),
              size=3.0, color="white", fontface="bold") +
    scale_fill_gradient(low="#E6F1FB", high="#185FA5",
                        name="% of group\nin sector") +
    scale_x_discrete(position="top") +
    labs(title    = "6. Labor composition by sector group",
         subtitle = "Share of each demographic group within sector workforce (baseline 2018)",
         x=NULL, y=NULL, caption=caption_src) +
    theme_mip() +
    theme(panel.grid=element_blank(),
          axis.text.x=element_text(angle=30, hjust=0, size=10),
          axis.text.y=element_text(size=10),
          legend.position="right")
  
  ggsave("fig6_labor_heatmap.png", p6, width=11, height=6, dpi=150)
  message("Saved fig6_labor_heatmap.png")
  invisible(p6)
}


# =============================================================================
# CHART 5 — ENERGY INTENSITY
# =============================================================================

plot_energy_intensity <- function(sectors = "energy") {
  # sectors: "energy" (9 sectors), "top20", or "all" (73 sectors)
  
  source_labels <- c(Derivados="Derivatives", Biodiesel="Biodiesel",
                     Etanol="Ethanol", EE_Central="EE Central",
                     EE_Distrib="EE Distrib", Gas_Natural="Gas Natural")
  
  source_colors <- c(
    Derivatives = "#E24B4A", Biodiesel   = "#BA7517",
    Ethanol     = "#3B6D11", "EE Central"= "#378ADD",
    "EE Distrib"= "#534AB7", "Gas Natural"= "#1D9E75"
  )
  
  intensity_df <- do.call(rbind, lapply(names(energy_rows), function(f) {
    vec <- suppressWarnings(
      as.numeric(as.character(unlist(sxs_raw[energy_rows[f], 4:(3+N)])))
    )
    vec[is.na(vec)] <- 0
    data.frame(cod=setores$cod, nome=setores$nome,
               fonte=source_labels[f],
               intens=vec / x_safe * 1000,   # x1000 for readability
               stringsAsFactors=FALSE)
  }))
  
  # Compute total per sector for ordering
  totals <- intensity_df |>
    group_by(cod, nome) |>
    summarise(total=sum(intens), .groups="drop") |>
    arrange(desc(total))
  
  # Filter by sectors argument
  selected <- switch(sectors,
                     energy = totals |> filter(cod %in% energy_sectors),
                     top20  = head(totals, 20),
                     all    = totals
  )
  
  n  <- nrow(selected)
  ht <- max(4, n * 0.38 + 1.2)
  
  df_plot <- intensity_df |>
    filter(cod %in% selected$cod) |>
    mutate(
      nome_short = stringr::str_trunc(paste0(cod, " ", nome), 45),
      nome_short = factor(nome_short,
                          levels = selected |>
                            mutate(lbl = stringr::str_trunc(
                              paste0(cod, " ", nome), 45)) |>
                            arrange(total) |> pull(lbl)),
      fonte = factor(fonte, levels = c("Derivatives","Biodiesel","Ethanol",
                                       "EE Central","EE Distrib","Gas Natural"))
    )
  
  subtitle <- paste0("ktep per R$1 million of output (x10-3), baseline 2018. n=", n, " sectors.")
  
  p7 <- ggplot(df_plot, aes(intens, nome_short, fill=fonte)) +
    geom_col(width=0.72, position="stack") +
    scale_fill_manual(values=source_colors, name="Energy source",
                      guide=guide_legend(nrow=1)) +
    scale_x_continuous(labels=label_number(accuracy=0.01),
                       expand=expansion(mult=c(0, 0.05))) +
    labs(title    = paste0("7. Energy intensity — ", sectors, " sectors"),
         subtitle = subtitle,
         x = "ktep per R$1 million (x10-3)", y = NULL,
         caption = caption_src) +
    theme_mip(base_size = if (n > 30) 9 else 11) +
    theme(legend.position = "bottom")
  
  fname <- paste0("fig7_energy_intensity_", sectors, ".png")
  ggsave(fname, p7, width=10, height=ht, dpi=150, limitsize=FALSE)
  message("Saved ", fname)
  invisible(p7)
}


# =============================================================================
# CHART 6 — SHOCK RESULTS: NT vs MODEL (4-group comparison)
# =============================================================================

plot_shock_comparison <- function(res,
                                  scenario_name = "+5% Exports",
                                  nt_gdp = c(Agropecuaria=8.152, Industria=8.693,
                                             Servicos=17.687, Energeticos=3.976),
                                  nt_emp = c(Agropecuaria=88.9, Industria=44.3,
                                             Servicos=123.6,  Energeticos=1.4)) {
  
  nt4_map <- setNames(
    rep(names(grupos_nt4), sapply(grupos_nt4, length)),
    unlist(grupos_nt4)
  )
  nt4_levels <- c("Agropecuaria","Industria","Servicos","Energeticos")
  
  model_gdp_raw <- sapply(nt4_levels, function(g) {
    secs <- names(nt4_map[nt4_map == g])
    sum(res$delta_va[secs], na.rm=TRUE) / 1e3
  })
  model_emp_raw <- sapply(nt4_levels, function(g) {
    secs <- names(nt4_map[nt4_map == g])
    sum(res$delta_emp[secs], na.rm=TRUE) / 1e3
  })
  
  df_gdp <- bind_rows(
    data.frame(grupo=names(nt_gdp),       value=as.numeric(nt_gdp),       source="NT published"),
    data.frame(grupo=names(model_gdp_raw), value=as.numeric(model_gdp_raw), source="Model")
  ) |> mutate(grupo = factor(grupo, levels=nt4_levels))
  
  df_emp <- bind_rows(
    data.frame(grupo=names(nt_emp),       value=as.numeric(nt_emp),       source="NT published"),
    data.frame(grupo=names(model_emp_raw), value=as.numeric(model_emp_raw), source="Model")
  ) |> mutate(grupo = factor(grupo, levels=nt4_levels))
  
  p_gdp <- ggplot(df_gdp, aes(grupo, value, fill=source)) +
    geom_col(position="dodge", width=0.6) +
    geom_text(aes(label=round(value,1)),
              position=position_dodge(0.6), vjust=-0.4, size=3) +
    scale_fill_manual(values=c("NT published"=PAL$nt, "Model"=PAL$renovavel)) +
    scale_y_continuous(labels=label_comma(suffix=" bi"),
                       expand=expansion(mult=c(0,0.15))) +
    labs(title=paste("GDP impact —", scenario_name),
         subtitle="NT 4-group comparison. R$ billion.",
         x=NULL, y="R$ billion", fill=NULL) +
    theme_mip() + theme(legend.position="top")
  
  p_emp <- ggplot(df_emp, aes(grupo, value, fill=source)) +
    geom_col(position="dodge", width=0.6) +
    geom_text(aes(label=round(value,1)),
              position=position_dodge(0.6), vjust=-0.4, size=3) +
    scale_fill_manual(values=c("NT published"=PAL$nt, "Model"=PAL$renovavel)) +
    scale_y_continuous(labels=label_comma(suffix="k"),
                       expand=expansion(mult=c(0,0.15))) +
    labs(title=paste("Employment impact —", scenario_name),
         subtitle="NT 4-group comparison. Thousand jobs.",
         x=NULL, y="Thousand jobs", fill=NULL) +
    theme_mip() + theme(legend.position="top")
  
  combined <- p_gdp + p_emp +
    plot_annotation(
      title   = paste("Shock results:", scenario_name),
      caption = caption_src,
      theme   = theme(plot.title=element_text(size=13, face="bold"))
    )
  
  fname <- paste0("fig_shock_", gsub("[^a-zA-Z0-9]","_",scenario_name), ".png")
  ggsave(fname, combined, width=11, height=5, dpi=150)
  message("Saved ", fname)
  invisible(combined)
}


# =============================================================================
# CHART 5 — ENERGY BY SOURCE: NT vs MODEL
# Works for any exercise — pass nt_energy as argument
# =============================================================================

plot_energy_comparison <- function(
    res,
    scenario_name = "+5% Exports",
    nt_energy = c(
      Derivados   = 1025,
      Biodiesel   = 46,
      Etanol      = 145,
      EE_Central  = 318,
      EE_Distrib  = 46,
      Transmissao = 188,
      Gas_Natural = 188
    )
) {
  
  # Standard order
  energy_order <- c(
    "Derivados",
    "Biodiesel",
    "Etanol",
    "EE_Central",
    "EE_Distrib",
    "Transmissao",
    "Gas_Natural"
  )
  
  # Labels for chart
  energy_labels <- c(
    Derivados   = "Derivatives",
    Biodiesel   = "Biodiesel",
    Etanol      = "Ethanol",
    EE_Central  = "EE Central",
    EE_Distrib  = "EE Distrib.",
    Transmissao = "Transmission",
    Gas_Natural = "Gas Natural"
  )
  
  # Model values
  model_energy <- res$delta_g
  
  # If model does not yet include Transmissao, add as NA
  model_complete <- setNames(rep(NA_real_, length(energy_order)), energy_order)
  model_complete[names(model_energy)] <- as.numeric(model_energy)
  
  # NT values
  has_nt <- !all(is.na(nt_energy))
  
  if (has_nt) {
    nt_complete <- setNames(rep(NA_real_, length(energy_order)), energy_order)
    nt_complete[names(nt_energy)] <- as.numeric(nt_energy)
    
    df_e <- dplyr::bind_rows(
      data.frame(
        fonte = names(nt_complete),
        ktep = as.numeric(nt_complete),
        source = "NT published"
      ),
      data.frame(
        fonte = names(model_complete),
        ktep = as.numeric(model_complete),
        source = "Model"
      )
    )
  } else {
    df_e <- data.frame(
      fonte = names(model_complete),
      ktep = as.numeric(model_complete),
      source = "Model"
    )
  }
  
  df_e <- df_e |>
    dplyr::filter(!is.na(ktep)) |>
    dplyr::mutate(
      fonte = factor(fonte, levels = energy_order)
    )
  
  p5 <- ggplot2::ggplot(df_e, ggplot2::aes(fonte, ktep, fill = source)) +
    ggplot2::geom_col(position = "dodge", width = 0.65) +
    ggplot2::geom_text(
      ggplot2::aes(label = round(ktep, 0)),
      position = ggplot2::position_dodge(0.65),
      vjust = -0.4,
      size = 3
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "NT published" = PAL$nt,
        "Model" = PAL$renovavel
      )
    ) +
    ggplot2::scale_x_discrete(labels = energy_labels) +
    ggplot2::labs(
      title = paste("Energy impact by source:", scenario_name),
      subtitle = if (has_nt) {
        "ktep — amber = NT published, teal = model"
      } else {
        "ktep — model results"
      },
      x = NULL,
      y = "ktep",
      fill = NULL,
      caption = caption_src
    ) +
    theme_mip() +
    ggplot2::theme(
      legend.position = "top",
      axis.text.x = ggplot2::element_text(angle = 20, hjust = 1)
    )
  
  fname <- paste0(
    "fig_energy_",
    gsub("[^a-zA-Z0-9]", "_", scenario_name),
    ".png"
  )
  
  ggplot2::ggsave(fname, p5, width = 9.5, height = 5, dpi = 150)
  message("Saved ", fname)
  
  invisible(p5)
}

# =============================================================================
# RUN ALL CHARTS
# =============================================================================

message("\n--- Generating all charts ---")

# Baseline charts (run immediately)
print(p1_combined)
print(p2_scatter)
print(p3_mult)
plot_labor_heatmap()
#plot_energy_intensity("energy")   # original — 9 energy sectors
#plot_energy_intensity("top20")    # top 20 most intensive
plot_energy_intensity("all")      # all 73 sectors

# Exercise 1 — +5% exports (NT values known)
plot_shock_comparison(res_ex1,
                      scenario_name = "Ex1: +5% Exports",
                      nt_gdp = c(Agropecuaria=8.152, Industria=8.693,
                                 Servicos=17.687,   Energeticos=3.976),
                      nt_emp = c(Agropecuaria=88.9, Industria=44.3,
                                 Servicos=123.6,   Energeticos=1.4))

plot_energy_comparison(
  res_ex1,
  scenario_name = "Ex1: +5% Exports",
  nt_energy = c(
    Derivados    = 1025.1,
    Biodiesel    = 46.2,
    Etanol       = 144.9,
    EE_Central   = 317.9,
    EE_Distrib   = 45.7,
    Transmissao  = 187.7,
    Gas_Natural  = 1767.6
  )
)

# Exercise 2 — +5% household S40 (fill NT values from Table 2 when available)
plot_shock_comparison(
  res_ex2,
  scenario_name = "Ex2: +5% Household EE",
  nt_gdp = c(
    Agropecuaria = 15.5   / 1000,
    Industria    = 172.3  / 1000,
    Servicos     = 782.1  / 1000,
    Energeticos  = 2540.9 / 1000
  ),
  nt_emp = c(
    Agropecuaria = 133.4  / 1000,
    Industria    = 1039.9 / 1000,
    Servicos     = 4672.0 / 1000,
    Energeticos  = 1319.1 / 1000
  )
)
plot_energy_comparison(
  res_ex2,
  scenario_name = "Ex2: +5% Household EE",
  nt_energy = c(
    Derivados    = 127.3,
    Biodiesel    = 1.4,
    Etanol       = 6.3,
    EE_Central   = 60.3,
    EE_Distrib   = 3.9,
    Transmissao  = 174.0,
    Gas_Natural  = 373.3
  )
)

message("\nDone. All 7 charts saved as PNG in working directory.")


# =============================================================================
# CHART 8 - PIE CONTRIBUTION OF ENERGY SECTORS
# =============================================================================
{
  # Requires: mip_epe_replication.R to have been run first
  #   Objects needed: sxs_raw, setores, N, energy_sectors
  #
  # Chart 1: Contribuição dos setores energéticos para o PIB
  # Chart 2: Contribuição dos setores energéticos para o VBP
  # Chart 3: Contribuição dos setores energéticos para o emprego
  # Chart 4: Contribuição dos setores energéticos para a remuneração
  
  
  # =============================================================================
  # 0. PACKAGES
  # =============================================================================
  install.packages("cowplot")
  packages <- c(
    "ggplot2", "dplyr", "tidyr", "scales",
    "patchwork", "here"
  )
  
  for (p in packages) {
    if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
    library(p, character.only = TRUE)
  }
  
  # Create output folder if needed
  if (!dir.exists(here("outputs"))) {
    dir.create(here("outputs"))
  }
  
  # =============================================================================
  # 1. BASE INDICATORS
  # =============================================================================
  
  row_map <- c(
    PIB         = 100,
    VBP         = 101,
    Emprego     = 102,
    Remuneracao = 88
  )
  
  energy_names_pt <- c(
    S05 = "Extração de petróleo e gás",
    S19 = "Derivados de petróleo",
    S20 = "Biodiesel",
    S21 = "Coquerias",
    S22 = "Biocombustíveis",
    S40 = "Geração centralizada de EE",
    S41 = "Geração distribuída de EE",
    S42 = "Transmissão de EE",
    S43 = "Gás Natural"
  )
  
  energy_colors <- c(
    S05 = "#4472C4",
    S19 = "#5B9BD5",
    S20 = "#44546A",
    S21 = "#FF0000",
    S22 = "#70AD47",
    S40 = "#FFC000",
    S41 = "#A9D18E",
    S42 = "#FF7C80",
    S43 = "#7030A0"
  )
  
  outer_colors <- c(
    "Setores energéticos" = "#595959",
    "Outros" = "#D9D9D9"
  )
  
  build_indicator <- function(row_r, indicator_name, unit_label) {
    
    vec <- suppressWarnings(
      as.numeric(as.character(unlist(sxs_raw[row_r, 4:(3 + N)])))
    )
    
    vec[is.na(vec)] <- 0
    names(vec) <- setores$cod
    
    total        <- sum(vec)
    energy_total <- sum(vec[energy_sectors])
    other_total  <- total - energy_total
    
    outer <- data.frame(
      cod   = c("Setores energéticos", "Outros"),
      label = c("Setores energéticos", "Outros"),
      value = c(energy_total, other_total),
      pct   = c(energy_total / total * 100, other_total / total * 100),
      ring  = "outer",
      stringsAsFactors = FALSE
    )
    
    inner <- data.frame(
      cod   = energy_sectors,
      label = energy_names_pt[energy_sectors],
      value = vec[energy_sectors],
      pct   = vec[energy_sectors] / total * 100,
      ring  = "inner",
      stringsAsFactors = FALSE
    ) |>
      filter(value > 0) |>
      arrange(desc(value))
    
    list(
      indicator  = indicator_name,
      unit       = unit_label,
      total      = total,
      energy_pct = energy_total / total * 100,
      outer      = outer,
      inner      = inner
    )
  }
  
  indicators <- list(
    build_indicator(row_map["PIB"],         "PIB",         "R$ milhões 2018"),
    build_indicator(row_map["VBP"],         "VBP",         "R$ milhões 2018"),
    build_indicator(row_map["Emprego"],     "Emprego",     "pessoas ocupadas"),
    build_indicator(row_map["Remuneracao"], "Remuneração", "R$ milhões 2018")
  )
  
  # =============================================================================
  # 2. THEME
  # =============================================================================
  
  theme_donut <- function(show_legend = FALSE) {
    theme_void() +
      theme(
        plot.title = element_text(
          size = 11,
          face = "bold",
          hjust = 0.5,
          margin = margin(b = 6)
        ),
        legend.position = ifelse(show_legend, "right", "none"),
        legend.title = element_blank(),
        legend.text = element_text(size = 9),
        plot.caption = element_text(
          size = 7.5,
          color = "grey50",
          hjust = 0
        )
      )
  }
  
  # =============================================================================
  # 3. SINGLE DONUT FUNCTION
  # =============================================================================
  
  plot_single_donut <- function(ind, chart_number, show_legend = TRUE) {
    
    outer <- ind$outer |>
      mutate(
        ymax = cumsum(pct / 100),
        ymin = c(0, head(ymax, -1)),
        ymid = (ymax + ymin) / 2,
        xmin = 4.0,
        xmax = 5.0,
        label_pct = sprintf("%.1f%%", pct)
      )
    
    inner <- ind$inner |>
      mutate(
        ymax = cumsum(pct / ind$energy_pct),
        ymin = c(0, head(ymax, -1)),
        ymid = (ymax + ymin) / 2,
        xmin = 2.5,
        xmax = 3.8,
        label_pct = sprintf("%.1f%%", pct)
      )
    
    df_all <- bind_rows(outer, inner)
    
    p <- ggplot(df_all) +
      geom_rect(
        aes(
          ymin = ymin,
          ymax = ymax,
          xmin = xmin,
          xmax = xmax,
          fill = cod
        ),
        color = "white",
        linewidth = 0.3
      ) +
      geom_text(
        data = df_all |> filter(ring == "inner"),
        aes(
          x = (xmin + xmax) / 2,
          y = ymid,
          label = label_pct
        ),
        size = 3.4,
        color = "white",
        fontface = "bold"
      ) +
      geom_text(
        data = df_all |> filter(ring == "outer", cod == "Setores energéticos"),
        aes(
          x = (xmin + xmax) / 2,
          y = ymid,
          label = label_pct
        ),
        size = 3.4,
        color = "white",
        fontface = "bold"
      ) +
      annotate(
        "text",
        x = 0,
        y = 0,
        label = sprintf("%s\n%.2f%%", ind$indicator, ind$energy_pct),
        size = 3.8,
        fontface = "bold",
        color = "grey20"
      ) +
      scale_fill_manual(
        values = c(outer_colors, energy_colors),
        labels = c(
          "Setores energéticos" = "Setores energéticos",
          "Outros" = "Outros",
          energy_names_pt
        )
      ) +
      coord_polar(theta = "y", direction = -1) +
      xlim(0, 5.5) +
      labs(
        title = paste0(
          chart_number,
          ". Contribuição dos setores energéticos para o ",
          ind$indicator
        )
      ) +
      theme_donut(show_legend = show_legend)
    
    fname <- sprintf(
      "fig_contribution_%d_%s.png",
      chart_number,
      tolower(gsub("[^a-z]", "", iconv(ind$indicator, to = "ASCII//TRANSLIT")))
    )
    
    ggsave(
      here("outputs", fname),
      p,
      width = 11,
      height = 6,
      dpi = 150
    )
    
    message(sprintf("Saved %s", fname))
    
    return(p)
  }
  
  # =============================================================================
  # 4. INDIVIDUAL CHARTS
  # =============================================================================
  
  individual_plots <- lapply(seq_along(indicators), function(i) {
    plot_single_donut(indicators[[i]], i, show_legend = TRUE)
  })
  
  # =============================================================================
  # 5. COMBINED 2x2 PANEL WITH LEGEND AND ALL ENERGY-SECTOR NUMBERS
  # =============================================================================
  
  plots_2x2 <- lapply(seq_along(indicators), function(i) {
    
    ind <- indicators[[i]]
    
    outer <- ind$outer |>
      mutate(
        ymax = cumsum(pct / 100),
        ymin = c(0, head(ymax, -1)),
        ymid = (ymax + ymin) / 2,
        xmin = 4.0,
        xmax = 5.0,
        label_pct = ifelse(cod == "Setores energéticos", sprintf("%.1f%%", pct), "")
      )
    
    inner <- ind$inner |>
      mutate(
        ymax = cumsum(pct / ind$energy_pct),
        ymin = c(0, head(ymax, -1)),
        ymid = (ymax + ymin) / 2,
        xmin = 2.5,
        xmax = 3.8,
        label_pct = sprintf("%.1f%%", pct)
      )
    
    df_all <- bind_rows(outer, inner)
    
    ggplot(df_all) +
      geom_rect(
        aes(
          ymin = ymin,
          ymax = ymax,
          xmin = xmin,
          xmax = xmax,
          fill = cod
        ),
        color = "white",
        linewidth = 0.25
      ) +
      geom_text(
        data = df_all |> filter(label_pct != ""),
        aes(
          x = (xmin + xmax) / 2,
          y = ymid,
          label = label_pct
        ),
        size = 3.4,
        color = "white",
        fontface = "bold"
      ) +
      annotate(
        "text",
        x = 0,
        y = 0,
        label = sprintf("%s\n%.2f%%", ind$indicator, ind$energy_pct),
        size = 3.4,
        fontface = "bold",
        color = "grey20"
      ) +
      scale_fill_manual(
        values = c(outer_colors, energy_colors),
        labels = c(
          "Setores energéticos" = "Setores energéticos",
          "Outros" = "Outros",
          energy_names_pt
        )
      ) +
      coord_polar(theta = "y", direction = -1) +
      xlim(0, 5.5) +
      labs(title = paste0(i, ". ", ind$indicator)) +
      theme_donut(show_legend = FALSE)
  })
  
  legend_plot <- plot_single_donut(indicators[[1]], 1, show_legend = TRUE) +
    theme(
      plot.title = element_blank(),
      legend.position = "right"
    )
  
  legend_only <- cowplot::get_legend(legend_plot)
  
  panel_main <- wrap_plots(plots_2x2, ncol = 2)
  
  panel <- panel_main +
    plot_annotation(
      title = "Contribuição dos setores energéticos para a economia brasileira (2018)",
      caption = "Fonte: MIP-EPE/FIPE 2018 (Anexo 2). Anel externo: energia vs outros. Anel interno: composição dos setores energéticos.",
      theme = theme(
        plot.title = element_text(
          size = 13,
          face = "bold",
          hjust = 0.5,
          margin = margin(b = 8)
        ),
        plot.caption = element_text(
          size = 7.5,
          color = "grey50",
          hjust = 0
        )
      )
    )
  
  final_panel <- cowplot::plot_grid(
    panel,
    legend_only,
    ncol = 2,
    rel_widths = c(1, 0.23)
  )
  
  ggsave(
    here("outputs", "fig_contribution_panel_2x2.png"),
    final_panel,
    width = 15,
    height = 11,
    dpi = 150
  )
  
  message("Saved fig_contribution_panel_2x2.png")
  message("All contribution charts complete.")
}