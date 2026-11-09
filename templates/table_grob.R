# A table rendered in R for a slide (gridExtra tableGrob): plain black text, a bold header and two horizontal rules,
# the first column left-aligned and the rest right-aligned, optional grey note lines under the table. The PNG is sized to the table, so the deck
# library places it without stretching.
#   source("table_grob.R")
#   table_png(df, "img/group_sizes.png", notes = c("Counts are persons."))
# Use this whenever a chart would only list numbers per item (group sizes, counts per design, estimates per outcome).
# Show the structure of the content in the table itself, so a reader sees what belongs to what:
#   indent   rows that belong to the row above get an indent level (0, 1, 2) in the first column;
#   bold     a group's heading row is bold (often with the other cells empty);
#   spanners a heading over several columns, list(list("Statin start", 2:3), list("No start", 4:5)), so the column
#            headers under it can be short ("n", "%") instead of repeating the group in every header;
#   rules    thin grey lines after these data rows, between groups;
#   wrap     the widest a column may get, in characters, c(Definition = 60); longer cells wrap onto more lines;
#   padding  horizontal and vertical cell padding in points; c(10, 5) for a long table.
suppressPackageStartupMessages({ library(gridExtra); library(gtable); library(grid) })

table_png <- function(df, file, notes = NULL, base_size = 18, family = "Arial", ink = "black", mute = "#595959",
                      align = NULL, res = 220, indent = NULL, bold = NULL, spanners = NULL, rules = NULL, wrap = NULL,
                      padding = c(14, 10)) {
  df <- as.data.frame(df, check.names = FALSE, stringsAsFactors = FALSE)
  df[] <- lapply(df, function(x) if (is.numeric(x)) ifelse(is.na(x), "", formatC(x, big.mark = ",", format = if (all(x == round(x), na.rm = TRUE)) "d" else "g")) else as.character(x))
  df[is.na(df)] <- ""
  if (!is.null(wrap)) {
    if (is.null(names(wrap))) names(wrap) <- names(df)[seq_along(wrap)]
    for (k in names(wrap)) df[[k]] <- vapply(df[[k]], function(s) paste(strwrap(s, wrap[[k]]), collapse = "\n"), "")
    names(df) <- vapply(names(df), function(h) if (h %in% names(wrap)) paste(strwrap(h, wrap[[h]]), collapse = "\n") else h, "")
  }
  if (!is.null(indent)) {   # non-breaking spaces survive tableGrob; each wrapped line gets the same indent
    pad <- strrep(" ", 4 * indent)
    df[[1]] <- mapply(function(s, p) paste0(p, gsub("\n", paste0("\n", p), s, fixed = TRUE)), df[[1]], pad, USE.NAMES = FALSE)
  }
  face <- if (is.null(bold)) rep("plain", nrow(df)) else ifelse(bold, "bold", "plain")
  multi <- any(grepl("\n", as.matrix(df), fixed = TRUE)); multi_head <- any(grepl("\n", names(df), fixed = TRUE))
  hj <- if (is.null(align)) c(0, rep(1, ncol(df) - 1)) else align
  xx <- ifelse(hj == 0, 0.02, 0.995)   # right-aligned text near the cell's right edge, so a header as wide as its column stays inside it
  tt <- ttheme_minimal(base_size = base_size, base_family = family, padding = unit(padding, "pt"),
    core = list(fg_params = list(hjust = rep(hj, each = nrow(df)), x = rep(xx, each = nrow(df)), col = ink,
                                 fontface = rep(face, times = ncol(df))), bg_params = list(fill = NA)),
    colhead = list(fg_params = list(hjust = hj, x = xx, col = ink, fontface = "bold"), bg_params = list(fill = NA)))
  g <- tableGrob(df, rows = NULL, theme = tt)
  # row heights from the number of lines in each row, so descenders and wrapped lines stay inside their row
  nlines <- function(x) lengths(regmatches(x, gregexpr("\n", x, fixed = TRUE))) + 1
  g$heights <- unit(c(max(nlines(names(df))), apply(as.matrix(df), 1, function(r) max(nlines(r)))) * base_size * 1.22 + 2 * padding[2], "pt")
  # with wrapped cells, body text starts at the top of its row (a label sits on its own first line) and headers sit
  # on the rule under them
  for (i in which(g$layout$name == "core-fg")) if (multi) { g$grobs[[i]]$y <- unit(1, "npc") - unit(padding[2], "pt"); g$grobs[[i]]$vjust <- 1 }
  for (i in which(g$layout$name == "colhead-fg")) if (multi_head) { g$grobs[[i]]$y <- unit(padding[2], "pt"); g$grobs[[i]]$vjust <- 0 }
  # text sits inside the cell's padding, so neighbouring columns keep a gap (a right-aligned number never touches the
  # left-aligned text of the next column)
  for (i in which(g$layout$name %in% c("core-fg", "colhead-fg"))) {
    h <- hj[g$layout$l[i]]
    g$grobs[[i]]$x <- if (h == 0) unit(padding[1] / 2, "pt") else if (h == 1) unit(1, "npc") - unit(padding[1] / 2, "pt") else unit(0.5, "npc")
  }
  head_row <- 1
  if (length(spanners)) {   # a row of group headings above the column headers, each underlined across its columns
    g <- gtable_add_rows(g, unit(base_size * 1.25 + 2 * padding[2], "pt"), pos = 0); head_row <- 2
    for (sp in spanners) {
      l <- min(sp[[2]]); r <- max(sp[[2]])
      g <- gtable_add_grob(g, textGrob(sp[[1]], y = 0.58, gp = gpar(fontfamily = family, fontsize = base_size, fontface = "bold", col = ink)),
                           t = 1, l = l, r = r, name = paste0("span", l))
      g <- gtable_add_grob(g, segmentsGrob(0.04, 0.12, 0.96, 0.12, gp = gpar(col = ink, lwd = 0.8)), t = 1, l = l, r = r, name = paste0("spanrule", l))
    }
  }
  rule <- function(g, t, lwd, col = ink) gtable_add_grob(g, segmentsGrob(0, 0, 1, 0, gp = gpar(col = col, lwd = lwd)), t = t, l = 1, r = ncol(g), name = paste0("rule", t))
  g <- rule(g, head_row, 1); g <- rule(g, nrow(g), 1)
  for (i in rules) g <- rule(g, head_row + i, 0.6, "#A6A6A6")
  # measure on a scratch device; notes wrap to the table's width
  ragg::agg_png(tempfile(fileext = ".png"), width = 30, height = 30, units = "in", res = 72)
  tw <- convertWidth(sum(g$widths), "in", valueOnly = TRUE)
  for (n in notes) {
    words <- strsplit(n, " ")[[1]]; lines <- character(0); cur <- ""
    for (w in words) { t <- if (cur == "") w else paste(cur, w)
      if (cur != "" && convertWidth(grobWidth(textGrob(t, gp = gpar(fontfamily = family, fontsize = base_size - 2))), "in", valueOnly = TRUE) > tw - 0.05) { lines <- c(lines, cur); cur <- w } else cur <- t }
    for (ln in c(lines, cur)) {
      g <- gtable_add_rows(g, unit(base_size * 1.15, "pt"))
      g <- gtable_add_grob(g, textGrob(ln, x = 0.005, hjust = 0, gp = gpar(fontfamily = family, fontsize = base_size - 2, col = mute)),
                           t = nrow(g), l = 1, r = ncol(g), clip = "off", name = paste0("note", nrow(g)))
    }
  }
  th <- convertHeight(sum(g$heights), "in", valueOnly = TRUE); notew <- 0
  invisible(dev.off())
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ragg::agg_png(file, width = max(tw, notew + 0.1) + 0.3, height = th + 0.3, units = "in", res = res, background = "white")
  pushViewport(viewport(x = 0.15 / (max(tw, notew + 0.1) + 0.3), just = "left", width = unit(tw, "in")))
  grid.draw(g); popViewport(); invisible(dev.off())
  invisible(file)
}

if (sys.nframe() == 0) {   # Rscript table_grob.R: a demonstration table with made-up numbers
  demo <- data.frame(Characteristic = c("Persons", "Age, years", "Under 50", "50 or older", "Female"),
                     n = c(1200, NA, 640, 560, 700), `%` = c("", "", "53.3", "46.7", "58.3"),
                     n2 = c(3450, NA, 1500, 1950, 1700), `%2` = c("", "", "43.5", "56.5", "49.3"), check.names = FALSE)
  names(demo) <- c("Characteristic", "n", "%", "n ", "% ")
  table_png(demo, "img/demo_table.png", indent = c(0, 0, 1, 1, 0), bold = c(FALSE, TRUE, FALSE, FALSE, FALSE),
            spanners = list(list("Drug A start", 2:3), list("No start", 4:5)), rules = 4,
            notes = "Made-up numbers for the demonstration.")
  cat("wrote img/demo_table.png\n")
}
