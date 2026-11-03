# A study design diagram in the style of Schneeweiss S et al., Ann Intern Med 2019;170:398-406: the cohort entry
# date (day 0) at the top, one box per criterion block over its assessment window, inclusion white and exclusion
# grey, black lines, time on the x-axis. Saved as PNG for slides and PDF for a paper.
#   source("design_diagram.R")
#   design_diagram(rows, entry = c("Cohort entry date (day 0)", "First qualifying visit"), file = "img/design")
# rows: a list of blocks, each list(kind = "incl" | "excl", from, to, head, lines). Days -365..0 are drawn to scale;
# a block that starts at -Inf is drawn from the folded left edge. A block with from == to is drawn as a narrow bar
# on that day.
suppressPackageStartupMessages(library(ggplot2))

design_diagram <- function(rows, entry, file, family = "Arial", right = 400, width = 11) {
  m <- "−"; NEG_INF <- -540; BREAK <- -455
  lh <- 0.36; gap <- 0.3; y <- 0; box <- list(); txt <- list()
  for (r in rows) {
    h <- lh * (length(r$lines) + 1) + 0.24
    top <- y; bot <- y - h; y <- bot - gap
    from <- if (is.infinite(r$from)) NEG_INF else r$from
    narrow <- from == r$to
    x0 <- if (narrow) r$to - 7 else from; x1 <- if (narrow) r$to + 7 else r$to
    box[[length(box) + 1]] <- data.frame(x0, x1, top, bot, fill = if (r$kind == "incl") "white" else "grey85")
    tx <- if (narrow) x1 + 11 else x0 + 9
    ys <- top - 0.12 - lh * (seq_len(length(r$lines) + 1) - 0.5)
    txt[[length(txt) + 1]] <- data.frame(x = tx, y = ys, label = c(r$head, r$lines), face = c("bold", rep("plain", length(r$lines))))
  }
  box <- do.call(rbind, box); txt <- do.call(rbind, txt)
  axis_y <- y - 0.15; entry_top <- 1.45; entry_bot <- 0.45
  p <- ggplot() +
    annotate("segment", x = 0, xend = 0, y = entry_bot, yend = axis_y, linewidth = 0.6) +
    geom_rect(data = box, aes(xmin = x0, xmax = x1, ymin = bot, ymax = top, fill = I(fill)), colour = "black", linewidth = 0.5) +
    geom_text(data = txt, aes(x, y, label = label, fontface = face), hjust = 0, family = family, size = 3.7) +
    annotate("rect", xmin = -175, xmax = 175, ymin = entry_bot, ymax = entry_top, fill = "white", colour = "black", linewidth = 0.9) +
    annotate("text", x = 0, y = (entry_top + entry_bot) / 2 + 0.17, label = entry[1], family = family, size = 4.1, fontface = "bold") +
    annotate("text", x = 0, y = (entry_top + entry_bot) / 2 - 0.2, label = if (length(entry) > 1) entry[2] else "", family = family, size = 3.7) +
    annotate("segment", x = NEG_INF, xend = right, y = axis_y, yend = axis_y, linewidth = 0.5,
             arrow = arrow(length = unit(0.12, "in"), type = "closed")) +
    annotate("segment", x = c(NEG_INF, -365, 0), xend = c(NEG_INF, -365, 0), y = axis_y, yend = axis_y - 0.12, linewidth = 0.5) +
    annotate("text", x = c(NEG_INF, -365, 0), y = axis_y - 0.32, label = c(paste0(m, "∞"), paste0(m, "365"), "0"), family = family, size = 3.7) +
    annotate("text", x = c(BREAK - 6, BREAK + 6), y = axis_y, label = "/", family = family, size = 5, fontface = "bold") +
    annotate("text", x = right, y = axis_y - 0.32, label = "Time (days)", hjust = 1, family = family, size = 3.7) +
    scale_x_continuous(limits = c(NEG_INF - 10, right + 5), expand = c(0, 0)) +
    scale_y_continuous(limits = c(axis_y - 0.5, entry_top + 0.05), expand = c(0, 0)) +
    theme_void(base_family = family) + theme(plot.margin = margin(10, 14, 6, 10))
  h <- (entry_top - axis_y + 0.55) * 0.62
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ggsave(paste0(file, ".png"), p, width = width, height = h, dpi = 220, device = ragg::agg_png, bg = "white")
  # cairo_pdf embeds the fonts; R builds without Cairo fall back to the base pdf device
  ggsave(paste0(file, ".pdf"), p, width = width, height = h, device = if (capabilities("cairo")) cairo_pdf else "pdf", bg = "white")
  invisible(p)
}

if (sys.nframe() == 0) {   # Rscript design_diagram.R: a demonstration diagram
  m <- "−"
  rows <- list(
    list(kind = "incl", from = -365, to = 0, head = sprintf("Inclusion assessment window, days [%s365, 0]", m),
         lines = c("Diagnosis code for the condition", "Laboratory value at or above the threshold")),
    list(kind = "incl", from = 0, to = 0, head = "Inclusion, day 0", lines = c("Age 18 or older")),
    list(kind = "excl", from = -365, to = -1, head = sprintf("Exclusion assessment window, days [%s365, %s1]", m, m),
         lines = "Earlier use of the study drug"),
    list(kind = "excl", from = -Inf, to = 0, head = sprintf("Exclusion assessment window, days [%s∞, 0]", m),
         lines = "Contraindication to the study drug"))
  design_diagram(rows, entry = c("Cohort entry date (day 0)", "Drug start, or a visit with no start"), file = "img/demo_design")
  cat("wrote img/demo_design.png and .pdf\n")
}
