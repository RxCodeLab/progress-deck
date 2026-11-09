# A study design diagram in the style of Schneeweiss S et al., Ann Intern Med 2019;170:398-406 (figure templates
# CC BY, REPEAT Initiative): the cohort entry date (day 0) at the top with a grey bar down to the time axis, one box
# per window in the paper's colours, white text in the boxes, and the follow-up window hatched in green. A window too
# narrow for its text (such as days [0, 0]) is drawn as a sliver with its text beside it in the same colour.
# Saved as PNG for slides and PDF for a paper.
#   source("design_diagram.R")
#   design_diagram(rows, entry = "First prescription of drug A", file = "img/design")
# rows: a list of windows, top to bottom, each list(kind, from, to, lines, head = NULL, days = NULL)
#   kind:  "inclusion" or "exclusion" (assessment windows for eligibility), "washout", "covariate", "exposure",
#          or "followup"; head defaults to "<Kind> assessment window" ("Washout window", "Follow-up window")
#   from, to: days relative to day 0; from = -Inf for "any time before"; to = Inf for an open end
#   lines: the criteria, one per element; long lines are wrapped to the box
#   days: the bracket text, by default "days [from, to]", put after the heading; give e.g. "days [31, censoring]"
# The x-axis is not to scale: days map through sign(d) * log(1 + |d| / k), so a year before day 0 and five years of
# follow-up both fit, and the boxes carry their days as text, as in the paper. notes are grey lines under the
# figure, for abbreviations and footnote marks.
suppressPackageStartupMessages(library(ggplot2))

DESIGN_COLOURS <- c(inclusion = "#1FADE4", exclusion = "#1FADE4", washout = "#7BA9C0", covariate = "#2D579A",
                    exposure = "#1F2A5C", followup = "#1DAF52")

design_diagram <- function(rows, entry, file, notes = NULL, family = "Arial", width = 12.3, k = 30, base_pt = 8.5) {
  m <- "−"
  head0 <- c(inclusion = "Inclusion assessment window", exclusion = "Exclusion assessment window", washout = "Washout window",
             covariate = "Covariate assessment window", exposure = "Exposure assessment window", followup = "Follow-up window")
  alias <- c(incl = "inclusion", excl = "exclusion")
  rows <- lapply(rows, function(r) { if (r$kind %in% names(alias)) r$kind <- alias[[r$kind]]; r })
  bad <- setdiff(vapply(rows, `[[`, "", "kind"), names(head0))
  if (length(bad)) stop("unknown window kind: ", paste(bad, collapse = ", "))
  g <- function(d) sign(d) * log1p(abs(d) / k)
  fin <- unlist(lapply(rows, function(r) c(r$from, r$to))); fin <- c(0, fin[is.finite(fin)])
  span <- diff(range(g(fin)))
  lo <- min(g(fin)) - 0.12 * span; hi <- max(g(fin)) + 0.08 * span   # -Inf and +Inf map to the edges
  if (any(vapply(rows, function(r) r$from == -Inf, TRUE))) lo <- lo - 0.1 * span
  # the cohort-entry heading is centred on day 0: keep half its width (up to 3.2 in) on the right of day 0
  ent_half <- min(3.2, max(nchar(c(entry, "Cohort entry date"))) * base_pt / 72 * 0.5 / 2 + 0.2)
  hi <- max(hi, (0 + ent_half * (hi - lo) / width) / (1 - ent_half / width))
  ux <- (hi - lo) / width                              # data units per inch
  X <- function(d) ifelse(d == -Inf, lo, ifelse(d == Inf, hi, g(d)))
  fmt_day <- function(d) ifelse(d == -Inf, paste0(m, "∞"), ifelse(d == Inf, "∞", gsub("-", m, format(d, big.mark = ","))))
  pt_in <- base_pt / 72; lh <- pt_in * 1.25; char_in <- pt_in * 0.5
  wrap <- function(s, inches) unlist(lapply(s, function(x) strwrap(x, max(12, floor(inches / char_in)))))
  sliver <- 0.07 * ux; bar_w <- 0.09 * ux
  y <- 0; boxes <- list(); texts <- list(); hatch <- list(); labels <- list()
  for (r in rows) {
    x0 <- X(r$from); x1 <- X(r$to); col <- DESIGN_COLOURS[[r$kind]]
    hd <- if (is.null(r$head)) head0[[r$kind]] else r$head
    dl <- if (is.null(r$days)) sprintf("days [%s, %s]", fmt_day(r$from), fmt_day(r$to)) else r$days
    hd <- paste0(hd, ", ", dl)
    box_in <- (x1 - x0) / ux
    narrow <- r$kind != "followup" && box_in < 1.7
    if (narrow) {                                      # a sliver at its days; text beside it in the box colour
      c0 <- (x0 + x1) / 2
      if (x1 - x0 < sliver) { x0 <- c0 - sliver / 2; x1 <- c0 + sliver / 2 }
      left <- c0 <= 0
      room <- if (left) (x0 - lo) / ux - 0.15 else (hi - x1) / ux - 0.15
      body <- wrap(r$lines, min(room, 4.2))
      n <- length(body) + 1; h <- lh * n + 0.07
      boxes[[length(boxes) + 1]] <- data.frame(x0, x1, top = y, bot = y - h, fill = col, line = NA)
      ys <- y - 0.035 - lh * (seq_len(n) - 0.5)
      texts[[length(texts) + 1]] <- data.frame(x = if (left) x0 - 0.08 * ux else x1 + 0.08 * ux, y = ys,
        label = c(hd, body), face = c("bold", rep("plain", n - 1)), col = col, hjust = if (left) 1 else 0)
    } else if (r$kind == "followup") {                 # hatched green, with a white label box inside
      body <- wrap(r$lines, min(box_in - 0.45, 3.6))
      n <- length(body) + 1; h <- lh * n + 0.22
      boxes[[length(boxes) + 1]] <- data.frame(x0, x1, top = y, bot = y - h, fill = "white", line = col)
      hatch[[length(hatch) + 1]] <- c(x0 = x0, x1 = x1, top = y, bot = y - h)
      tw <- min(max(nchar(c(hd, body))) * char_in + 0.25, box_in - 0.2)
      cx <- (x0 + x1) / 2
      labels[[length(labels) + 1]] <- data.frame(x0 = cx - tw / 2 * ux, x1 = cx + tw / 2 * ux, top = y - 0.06, bot = y - h + 0.06)
      ys <- y - 0.11 - lh * (seq_len(n) - 0.5)
      texts[[length(texts) + 1]] <- data.frame(x = cx, y = ys, label = c(hd, body),
        face = c("bold", rep("plain", n - 1)), col = "black", hjust = 0.5)
    } else {
      body <- wrap(r$lines, box_in - 0.25)
      n <- length(body) + 1; h <- lh * n + 0.08
      boxes[[length(boxes) + 1]] <- data.frame(x0, x1, top = y, bot = y - h, fill = col, line = NA)
      ys <- y - 0.04 - lh * (seq_len(n) - 0.5)
      texts[[length(texts) + 1]] <- data.frame(x = (x0 + x1) / 2, y = ys, label = c(hd, body),
        face = c("bold", rep("plain", n - 1)), col = "white", hjust = 0.5)
    }
    y <- y - h - 0.05
  }
  boxes <- do.call(rbind, boxes); texts <- do.call(rbind, texts)
  axis_y <- y - 0.12
  ew <- wrap(entry, 6); ew[1] <- paste0("(", ew[1]); ew[length(ew)] <- paste0(ew[length(ew)], ")")
  ent <- c("Cohort entry date", ew, "Day 0")
  ent_y <- 0.12 + lh * (rev(seq_along(ent)) - 0.5)
  top <- max(ent_y) + lh * 0.7
  # hatching at 45 degrees in inches, clipped to each follow-up box
  hseg <- do.call(rbind, lapply(hatch, function(b) {
    X0 <- b[["x0"]] / ux; X1 <- b[["x1"]] / ux; Y0 <- b[["bot"]]; Y1 <- b[["top"]]; s <- 0.075
    cs <- seq(X0 - Y1, X1 - Y0, by = s)
    xa <- pmax(X0, Y0 + cs); xb <- pmin(X1, Y1 + cs); ok <- xb > xa
    data.frame(x = xa[ok] * ux, xend = xb[ok] * ux, y = xa[ok] - cs[ok], yend = xb[ok] - cs[ok])
  }))
  ylo <- axis_y - 0.3; height <- top - ylo
  nl <- if (length(notes)) wrap(notes, width - 0.2) else character(0)
  if (length(nl)) { ylo <- axis_y - 0.42 - lh * length(nl); height <- top - ylo }
  p <- ggplot() +
    annotate("rect", xmin = -bar_w / 2, xmax = bar_w / 2, ymin = axis_y, ymax = min(ent_y) - lh * 0.6, fill = "#D9D9D9") +
    geom_rect(data = boxes, aes(xmin = x0, xmax = x1, ymin = bot, ymax = top, fill = I(fill), colour = I(line)), linewidth = 0.6)
  if (!is.null(hseg)) p <- p + geom_segment(data = hseg, aes(x, y, xend = xend, yend = yend), colour = DESIGN_COLOURS[["followup"]], linewidth = 0.35)
  if (length(labels)) p <- p + geom_rect(data = do.call(rbind, labels), aes(xmin = x0, xmax = x1, ymin = bot, ymax = top), fill = "white", colour = DESIGN_COLOURS[["followup"]], linewidth = 0.4)
  p <- p +
    geom_text(data = texts, aes(x, y, label = label, fontface = face, colour = I(col), hjust = hjust), family = family, size = base_pt / .pt) +
    annotate("text", x = 0, y = ent_y, label = ent, fontface = c("bold", rep("plain", length(ent) - 2), "bold"), family = family, size = base_pt / .pt) +
    annotate("segment", x = lo, xend = hi, y = axis_y, yend = axis_y, linewidth = 0.9, arrow = arrow(length = unit(0.1, "in"), type = "closed")) +
    annotate("point", x = lo, y = axis_y, size = 2.4) +
    annotate("point", x = 0, y = axis_y + 0.07, shape = 25, size = 2.4, fill = "#BFBFBF", colour = "#BFBFBF") +
    annotate("text", x = hi, y = axis_y - 0.17, label = "Time", hjust = 1, fontface = "bold", family = family, size = base_pt / .pt)
  if (length(nl)) p <- p + annotate("text", x = lo, y = axis_y - 0.36 - lh * (seq_along(nl) - 1), label = nl, hjust = 0, vjust = 1,
                                    colour = "#404040", family = family, size = (base_pt - 1) / .pt)
  p <- p + scale_x_continuous(limits = c(lo, hi), expand = c(0, 0)) +
    scale_y_continuous(limits = c(ylo, top), expand = c(0, 0)) +
    theme_void(base_family = family) + theme(plot.margin = margin(2, 5, 2, 5))
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ggsave(paste0(file, ".png"), p, width = width, height = height, dpi = 220, device = ragg::agg_png, bg = "white")
  # cairo_pdf embeds the fonts; R builds without Cairo fall back to the base pdf device
  ggsave(paste0(file, ".pdf"), p, width = width, height = height, device = if (capabilities("cairo")) cairo_pdf else "pdf", bg = "white")
  invisible(p)
}

if (sys.nframe() == 0) {   # Rscript design_diagram.R: a demonstration diagram (a new-user cohort, made up)
  rows <- list(
    list(kind = "washout", from = -365, to = -1, lines = "No use of drug A or drug B"),
    list(kind = "exclusion", from = -Inf, to = 0, lines = "Contraindication to drug A or drug B"),
    list(kind = "inclusion", from = -365, to = 0, lines = c("Diagnosis code for the condition", "Continuous enrolment")),
    list(kind = "exclusion", from = 0, to = 0, lines = "Age under 18"),
    list(kind = "covariate", from = -365, to = -1, lines = "Baseline conditions and drugs"),
    list(kind = "covariate", from = 0, to = 0, lines = "Age, sex"),
    list(kind = "followup", from = 1, to = 1825, lines = character(0), days = "days [1, censoring*]"))
  design_diagram(rows, entry = "First prescription of drug A or drug B", file = "img/demo_design",
                 notes = "* The earliest of the outcome, switching or stopping, death, end of records, or day 1,825.")
  cat("wrote img/demo_design.png and .pdf\n")
}
