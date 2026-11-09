# Cumulative incidence (1 - Kaplan-Meier), 95% CIs and unweighted numbers at risk, in Okabe-Ito colours (vermilion for the first group, the target arm, then blue, ...)
# unless `colours` is given. The first two have 3.9:1 and 5.2:1 contrast on white and stay apart with red-green colour
# blindness; the later ones are lighter, so give more than two groups different `linetypes` as well.
#   source("cum_incidence.R")
#   cum_incidence_png(time, event, group, "img/incidence.png", times = 0:5, xlab = "Years")
#   source("table_grob.R"); tab <- cum_incidence_diff(time, event, group, 1:5, time_name = "Year")
#   table_png(tab, "img/difference.png", notes = attr(tab, "note"))   # the note says which group minus which
# Times use the same units as time; ymax is a proportion. The first factor level is the target/treated arm: a numeric 0/1
# group sorts 0 first, so pass factor(treatment, levels = c(1, 0)). Curves stop at each group's last follow-up time, and
# the difference table gives NA beyond it.
# 1 - Kaplan-Meier is the cumulative incidence of a single event type. With competing risks (for example death before the
# outcome), use the Aalen-Johansen estimator instead (survfit with a multistate factor as the event; survival's "compete"
# vignette). For model-standardised curves, draw the analysis's own estimates.
# With weights or a cluster, CIs use the robust variance, clustered on `cluster` (for example the matched set) when given.
# The difference CI is a Wald interval that assumes independent groups. Matched groups are not independent: when the
# analysis has its own CIs (bootstrap over matched sets, for example), put those in the table instead.
# digits = NULL gives one decimal, or two when every risk is under 5%.
suppressPackageStartupMessages({ library(survival); library(ggplot2); library(grid); library(gridExtra); library(gtable) })

.cum_incidence_fit <- function(time, event, group, weights, labels, cluster = NULL) {
  n <- length(time)
  if (!is.numeric(time) || !n || any(!is.finite(time) | time < 0)) stop("time must be finite and nonnegative.")
  if (length(event) != n || !(is.numeric(event) || is.logical(event)) || anyNA(event) || any(!event %in% 0:1))
    stop("event must have one 0/1 value per person.")
  if (length(group) != n || anyNA(group)) stop("group must have one nonmissing value per person.")
  group <- if (is.factor(group)) droplevels(group) else factor(group)
  lev <- levels(group)
  if (length(lev) < 2) stop("group must have at least two observed levels.")
  if (is.null(labels)) labels <- lev else {
    if (!is.null(names(labels))) {
      if (anyDuplicated(names(labels)) || !all(lev %in% names(labels))) stop("Named labels must cover every group level.")
      labels <- labels[lev]
    }
    if (length(labels) != length(lev) || anyNA(labels)) stop("Supply one display label per group level.")
  }
  d <- data.frame(time = time, event = as.integer(event), group = group)
  if (is.null(weights) && is.null(cluster)) fit <- survfit(Surv(time, event) ~ group, data = d, conf.int = 0.95) else {
    if (is.null(weights)) weights <- rep(1, n)
    if (!is.numeric(weights) || length(weights) != n || any(!is.finite(weights) | weights < 0) ||
        any(tapply(weights, group, sum) <= 0)) stop("weights must be finite, nonnegative, and have a positive sum in each group.")
    if (!is.null(cluster) && (length(cluster) != n || anyNA(cluster))) stop("cluster must have one nonmissing value per person.")
    d$cl <- if (is.null(cluster)) seq_len(n) else cluster
    fit <- survfit(Surv(time, event) ~ group, data = d, weights = weights, cluster = cl, robust = TRUE, conf.int = 0.95)
  }
  list(fit = fit, time = time, group = group, levels = lev, labels = unname(as.character(labels)))
}

.cum_incidence_times <- function(times) {
  if (!is.numeric(times) || !length(times) || any(!is.finite(times) | times < 0)) stop("times must be finite and nonnegative.")
  sort(unique(times))
}

cum_incidence_png <- function(time, event, group, file, weights = NULL, cluster = NULL, labels = NULL, times = NULL,
                              xlab = "Time", ylab = "Cumulative incidence", ymax = NULL, colours = NULL, linetypes = NULL,
                              width = 7, height = 5.3, base_size = 16, family = "Arial", res = 220) {
  z <- .cum_incidence_fit(time, event, group, weights, labels, cluster)
  if (is.null(times)) times <- pretty(c(0, if (max(time) > 0) max(time) else 1), n = 5)
  times <- .cum_incidence_times(times)
  xmax <- max(times); ng <- length(z$levels)
  if (xmax <= 0) stop("The plot needs at least one positive time break.")
  curves <- lapply(seq_len(ng), function(i) {
    f <- z$fit[i]
    d <- data.frame(time = c(0, f$time), incidence = c(0, 1 - f$surv),
                    lower = c(0, 1 - f$upper), upper = c(0, 1 - f$lower))
    end <- min(xmax, max(z$time[z$group == z$levels[i]]))   # stop at the group's last follow-up
    d <- d[d$time <= end, ]
    if (tail(d$time, 1) < end) d <- rbind(d, transform(tail(d, 1), time = end))
    d$group <- factor(z$levels[i], levels = z$levels)
    d
  })
  curve <- do.call(rbind, curves)
  # Duplicate each interval's bounds at its right edge, so the ribbon steps with the KM curve.
  ribbon <- do.call(rbind, lapply(curves, function(d) {
    s <- d[head(rep(seq_len(nrow(d)), each = 2), -1), ]
    s$time <- c(d$time[1], rep(d$time[-1], each = 2))
    s
  }))
  if (is.null(ymax)) ymax <- min(1, tail(pretty(c(0, max(curve$upper, curve$incidence, 0.01, na.rm = TRUE)), n = 4), 1))
  if (length(ymax) != 1 || !is.finite(ymax) || ymax <= 0 || ymax > 1) stop("ymax must be a proportion in (0, 1].")
  # Okabe-Ito order unless colours are given (for example colours = c("black", "black"), linetypes = c("solid", "dashed") for print)
  if (is.null(colours)) colours <- rep(c("#D55E00", "#0072B2", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#000000"), length.out = ng)
  if (length(colours) < ng) stop("Supply one colour per group.")
  colours <- colours[seq_len(ng)]
  types <- if (is.null(linetypes)) rep("solid", ng) else rep(linetypes, length.out = ng)
  xscale <- function() scale_x_continuous(breaks = times, limits = c(0, xmax), expand = expansion(mult = 0))
  # right margin: room for half of the widest at-risk count, which is centred on the last break
  rmar <- max(18, (base_size - 2) * 0.3 * nchar(format(max(table(z$group)), big.mark = ",")) + 6)
  p <- ggplot(curve, aes(x = time, group = group)) +
    geom_ribbon(data = ribbon, aes(ymin = lower, ymax = upper, fill = group), alpha = 0.13, colour = NA) +
    geom_step(aes(y = incidence, colour = group, linetype = group), linewidth = 1.1, direction = "hv") +
    scale_colour_manual(values = colours, breaks = z$levels, labels = z$labels) +
    scale_fill_manual(values = colours, guide = "none") +
    scale_linetype_manual(values = types, breaks = z$levels, labels = z$labels) + xscale() +
    scale_y_continuous(breaks = pretty(c(0, ymax), n = 4), labels = function(x) paste0(sapply(100 * x, format, trim = TRUE), "%")) +
    coord_cartesian(ylim = c(0, ymax), expand = FALSE) + labs(x = xlab, y = ylab) +
    theme_classic(base_size = base_size, base_family = family) +
    theme(axis.text = element_text(colour = "black"), axis.line = element_line(colour = "black"),
          legend.position = "inside", legend.position.inside = c(0.03, 0.97), legend.justification = c(0, 1),
          legend.title = element_blank(), legend.background = element_blank(), legend.key = element_blank(),
          legend.text = element_text(size = base_size - 2), legend.key.height = unit(0.9, "lines"),
          legend.margin = margin(0, 0, 0, 0), plot.margin = margin(8, rmar, 4, 8))
  risk <- do.call(rbind, lapply(seq_len(ng), function(i)
    data.frame(time = times, row = ng - i + 1, count = vapply(times, function(t) sum(time[z$group == z$levels[i]] >= t), integer(1)))))
  risk$lab <- format(risk$count, big.mark = ",", trim = TRUE)
  r <- ggplot(risk, aes(time, row, label = lab)) +
    geom_text(size = (base_size - 2) / (72.27 / 25.4), family = family) + xscale() +
    scale_y_continuous(breaks = seq_len(ng), labels = rev(z$labels), limits = c(0.5, ng + 0.5), expand = expansion(mult = 0)) +
    coord_cartesian(clip = "off") + labs(title = "No. at risk") +
    theme_void(base_size = base_size, base_family = family) +
    theme(axis.text.y = element_text(colour = "black", hjust = 1, size = base_size - 2,
                                     margin = margin(r = (base_size - 2) * max(nchar(risk$lab)) * 0.3 + 8)),
          plot.title = element_text(size = base_size - 1, margin = margin(b = 5)), plot.title.position = "plot",
          plot.margin = margin(2, rmar, 8, 8))
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ragg::agg_png(file, width = width, height = height, units = "in", res = res, background = "white")
  on.exit(dev.off(), add = TRUE)
  pg <- ggplotGrob(p); rg <- ggplotGrob(r)
  pg$widths <- rg$widths <- unit.pmax(pg$widths, rg$widths)
  risk_height <- unit((ng + 1) * (base_size + 5) + 14, "pt")
  grid.draw(arrangeGrob(pg, rg, ncol = 1, heights = unit.c(unit(1, "npc") - risk_height, risk_height)))
  invisible(list(file = file, fit = z$fit))
}

cum_incidence_diff <- function(time, event, group, times, weights = NULL, cluster = NULL, labels = NULL, digits = NULL,
                               time_name = "Time", ci_newline = TRUE) {
  z <- .cum_incidence_fit(time, event, group, weights, labels, cluster)
  times <- .cum_incidence_times(times)
  summaries <- lapply(seq_along(z$levels), function(i) {
    s <- summary(z$fit[i], times = times, extend = TRUE)
    beyond <- times > max(z$time[z$group == z$levels[i]])   # not followed that long: no estimate
    for (k in c("surv", "lower", "upper", "std.err")) s[[k]][beyond] <- NA
    s
  })
  if (is.null(digits)) {   # one decimal, or two when every risk in the table is under 5% (one would round them to 0.x)
    top <- max(vapply(summaries, function(s) max(c(0, 1 - s$lower), na.rm = TRUE), numeric(1)))
    digits <- if (top < 0.05) 2 else 1
  }
  num <- function(x) sub("^-", "\u2212", sub("^-(0(\\.0*)?)$", "\\1", sprintf("%.*f", digits, 100 * x)))   # minus signs, no "-0.0"
  sep <- if (ci_newline) "\n(" else " ("
  fmt <- function(est, lower, upper) ifelse(is.na(est), "NA", paste0(num(est), sep, num(lower), " to ", num(upper), ")"))
  out <- data.frame(times, check.names = FALSE); names(out) <- time_name
  for (i in seq_along(summaries)) {
    s <- summaries[[i]]
    out[[i + 1]] <- fmt(1 - s$surv, 1 - s$upper, 1 - s$lower)
  }
  if (length(summaries) == 2) {
    a <- summaries[[1]]; b <- summaries[[2]]
    difference <- b$surv - a$surv
    # summary.survfit supplies survival-scale SEs for both ordinary and robust fits.
    half <- qnorm(0.975) * sqrt(a$std.err^2 + b$std.err^2)
    out[["Difference\npoints (95% CI)"]] <- fmt(difference, difference - half, difference + half)
    attr(out, "note") <- paste0("Difference: ", z$labels[1], " minus ", z$labels[2], ", in percentage points.")
  }
  names(out)[seq_along(z$labels) + 1] <- paste0(z$labels, "\n% (95% CI)")
  out
}

if (sys.nframe() == 0) {   # Rscript cum_incidence.R: made-up data, with follow-up in years
  set.seed(20261105)
  n <- 2000
  group <- factor(rep(c("Treated", "Control"), each = n / 2), levels = c("Treated", "Control"))
  failure <- rexp(n, rate = ifelse(group == "Treated", 0.04, 0.06))
  censor <- pmin(runif(n, 1, 8), 5)   # administrative end at 5 years
  time <- pmin(failure, censor); event <- as.integer(failure <= censor)
  cum_incidence_png(time, event, group, "img/demo_cum_incidence.png", times = 0:5, xlab = "Years")
  script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
  source(file.path(dirname(normalizePath(script)), "table_grob.R"))
  tab <- cum_incidence_diff(time, event, group, 1:5, time_name = "Year")
  table_png(tab, "img/demo_cum_incidence_diff.png", notes = c(attr(tab, "note"), "Made-up data; independent-group Wald CI."))
  cat("wrote img/demo_cum_incidence.png\nwrote img/demo_cum_incidence_diff.png\n")
}
