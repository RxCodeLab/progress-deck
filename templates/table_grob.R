# A table rendered in R for a slide (gridExtra tableGrob): plain black text, a bold header and two horizontal rules,
# the first column left-aligned and the rest right-aligned, optional grey note lines under the table. The PNG is sized to the table, so the deck
# library places it without stretching.
#   source("table_grob.R")
#   table_png(df, "img/group_sizes.png", notes = c("Counts are persons."))
# Use this whenever a chart would only list numbers per item (group sizes, counts per design, estimates per outcome).
suppressPackageStartupMessages({ library(gridExtra); library(gtable); library(grid) })

table_png <- function(df, file, notes = NULL, base_size = 18, family = "Arial", ink = "black", mute = "#595959",
                      align = NULL, res = 220) {
  df <- as.data.frame(df, check.names = FALSE, stringsAsFactors = FALSE)
  df[] <- lapply(df, function(x) if (is.numeric(x)) formatC(x, big.mark = ",", format = if (all(x == round(x), na.rm = TRUE)) "d" else "g") else as.character(x))
  hj <- if (is.null(align)) c(0, rep(1, ncol(df) - 1)) else align
  xx <- ifelse(hj == 0, 0.02, 0.995)   # right-aligned text near the cell's right edge, so a header as wide as its column stays inside it
  tt <- ttheme_minimal(base_size = base_size, base_family = family, padding = unit(c(14, 12), "pt"),
    core = list(fg_params = list(hjust = rep(hj, each = nrow(df)), x = rep(xx, each = nrow(df)), col = ink), bg_params = list(fill = NA)),
    colhead = list(fg_params = list(hjust = hj, x = xx, col = ink, fontface = "bold"), bg_params = list(fill = NA)))
  g <- tableGrob(df, rows = NULL, theme = tt)
  rule <- function(g, t, lwd) gtable_add_grob(g, segmentsGrob(0, 0, 1, 0, gp = gpar(col = ink, lwd = lwd)), t = t, l = 1, r = ncol(g), name = paste0("rule", t))
  g <- rule(g, 1, 1); g <- rule(g, nrow(g), 1)
  for (n in notes) {
    g <- gtable_add_rows(g, unit(18, "pt"))
    g <- gtable_add_grob(g, textGrob(n, x = 0.01, hjust = 0, gp = gpar(fontfamily = family, fontsize = base_size - 1, col = mute)),
                         t = nrow(g), l = 1, r = ncol(g), name = paste0("note", nrow(g)))
  }
  # measure on a scratch device, then draw at the table's own size
  ragg::agg_png(tempfile(fileext = ".png"), width = 30, height = 30, units = "in", res = 72)
  tw <- convertWidth(sum(g$widths), "in", valueOnly = TRUE); th <- convertHeight(sum(g$heights), "in", valueOnly = TRUE)
  invisible(dev.off())
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ragg::agg_png(file, width = tw + 0.3, height = th + 0.3, units = "in", res = res, background = "white")
  grid.draw(g); invisible(dev.off())
  invisible(file)
}

if (sys.nframe() == 0) {   # Rscript table_grob.R: a demonstration table with made-up numbers
  demo <- data.frame(Analysis = c("Drug A start vs no start", "Lab value high vs normal", "Trajectory groups"),
                     Persons = c(1200, 3450, 980), Events = c(150, 610, 220), check.names = FALSE)
  table_png(demo, "img/demo_table.png", notes = "Made-up numbers for the demonstration.")
  cat("wrote img/demo_table.png\n")
}
