# Cumulative incidence (1 - Kaplan-Meier), 95% CIs and unweighted numbers at risk, in black and grey.
#   source("cum_incidence.R")
#   cum_incidence_png(time, event, group, "img/incidence.png", times = 0:5)
#   source("table_grob.R"); table_png(cum_incidence_diff(time, event, group, 1:5), "img/difference.png")
# Times use the same units as time; ymax is a proportion. The first group is the target/treated arm.
# The Wald CI assumes independent groups; when the analysis has its own CIs (bootstrap, matched pairs),
# put those in the table instead. Estimates at times beyond follow-up carry the last estimate forward.
suppressPackageStartupMessages({ library(survival); library(ggplot2); library(grid); library(gridExtra); library(gtable) })

.cum_incidence_fit <- function(time, event, group, weights, labels) {
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
  if (is.null(weights)) fit <- survfit(Surv(time, event) ~ group, data = d, conf.int = 0.95) else {
    if (!is.numeric(weights) || length(weights) != n || any(!is.finite(weights) | weights < 0) ||
        any(tapply(weights, group, sum) <= 0)) stop("weights must be finite, nonnegative, and have a positive sum in each group.")
    fit <- survfit(Surv(time, event) ~ group, data = d, weights = weights, id = seq_along(time), robust = TRUE, conf.int = 0.95)
  }
  list(fit = fit, time = time, group = group, levels = lev, labels = unname(as.character(labels)))
}

.cum_incidence_times <- function(times) {
  if (!is.numeric(times) || !length(times) || any(!is.finite(times) | times < 0)) stop("times must be finite and nonnegative.")
  sort(unique(times))
}

cum_incidence_png <- function(time, event, group, file, weights = NULL, labels = NULL, times = NULL,
                              xlab = "Years", ylab = "Cumulative incidence", ymax = NULL,
                              width = 7, height = 5.3, base_size = 16, family = "Arial", res = 220) {
  z <- .cum_incidence_fit(time, event, group, weights, labels)
  if (is.null(times)) times <- pretty(c(0, if (max(time) > 0) max(time) else 1), n = 5)
  times <- .cum_incidence_times(times)
  xmax <- max(times); ng <- length(z$levels)
  if (xmax <= 0) stop("The plot needs at least one positive time break.")
  curves <- lapply(seq_len(ng), function(i) {
    f <- z$fit[i]
    d <- data.frame(time = c(0, f$time), incidence = c(0, 1 - f$surv),
                    lower = c(0, 1 - f$upper), upper = c(0, 1 - f$lower))
    d <- d[d$time <= xmax, ]
    if (tail(d$time, 1) < xmax) d <- rbind(d, transform(tail(d, 1), time = xmax))
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
  colours <- rep(c("black", "#7F7F7F"), length.out = ng)
  types <- rep(rep(c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash"), each = 2), length.out = ng)
  xscale <- function() scale_x_continuous(breaks = times, limits = c(0, xmax), expand = expansion(mult = 0))
  p <- ggplot(curve, aes(x = time, group = group)) +
    geom_ribbon(data = ribbon, aes(ymin = lower, ymax = upper, fill = group), alpha = 0.13, colour = NA) +
    geom_step(aes(y = incidence, colour = group, linetype = group), linewidth = 0.8, direction = "hv") +
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
          legend.margin = margin(0, 0, 0, 0), plot.margin = margin(8, 18, 4, 8))
  risk <- do.call(rbind, lapply(seq_len(ng), function(i)
    data.frame(time = times, row = ng - i + 1, count = vapply(times, function(t) sum(time[z$group == z$levels[i]] >= t), integer(1)))))
  r <- ggplot(risk, aes(time, row, label = count)) +
    geom_text(size = (base_size - 2) / (72.27 / 25.4), family = family) + xscale() +
    scale_y_continuous(breaks = seq_len(ng), labels = rev(z$labels), limits = c(0.5, ng + 0.5), expand = expansion(mult = 0)) +
    coord_cartesian(clip = "off") + labs(title = "No. at risk") +
    theme_void(base_size = base_size, base_family = family) +
    theme(axis.text.y = element_text(colour = "black", hjust = 1, size = base_size - 2,
                                     margin = margin(r = (base_size - 2) * max(nchar(risk$count)) * 0.3 + 8)),
          plot.title = element_text(size = base_size - 1, margin = margin(b = 5)), plot.title.position = "plot",
          plot.margin = margin(2, 18, 8, 8))
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  ragg::agg_png(file, width = width, height = height, units = "in", res = res, background = "white")
  on.exit(dev.off(), add = TRUE)
  pg <- ggplotGrob(p); rg <- ggplotGrob(r)
  pg$widths <- rg$widths <- unit.pmax(pg$widths, rg$widths)
  risk_height <- unit((ng + 1) * (base_size + 5) + 14, "pt")
  grid.draw(arrangeGrob(pg, rg, ncol = 1, heights = unit.c(unit(1, "npc") - risk_height, risk_height)))
  invisible(list(file = file, fit = z$fit))
}

cum_incidence_diff <- function(time, event, group, times, weights = NULL, labels = NULL, digits = 1) {
  z <- .cum_incidence_fit(time, event, group, weights, labels)
  times <- .cum_incidence_times(times)
  summaries <- lapply(seq_along(z$levels), function(i) summary(z$fit[i], times = times, extend = TRUE))
  num <- function(x) sub("^-(0(\\.0*)?)$", "\\1", sprintf("%.*f", digits, 100 * x))   # no "-0.0"
  fmt <- function(est, lower, upper) paste0(num(est), " (", num(lower), " to ", num(upper), ")")
  out <- data.frame(Year = times, check.names = FALSE)
  for (i in seq_along(summaries)) {
    s <- summaries[[i]]
    out[[i + 1]] <- fmt(1 - s$surv, 1 - s$upper, 1 - s$lower)
  }
  if (length(summaries) == 2) {
    a <- summaries[[1]]; b <- summaries[[2]]
    difference <- b$surv - a$surv
    # summary.survfit supplies survival-scale SEs for both ordinary and robust fits.
    half <- qnorm(0.975) * sqrt(a$std.err^2 + b$std.err^2)
    out[["Difference (95% CI), percentage points"]] <- fmt(difference, difference - half, difference + half)
  }
  names(out)[seq_along(z$labels) + 1] <- paste0(z$labels, " (95% CI), %")
  out
}

if (sys.nframe() == 0) {   # Rscript cum_incidence.R: made-up data, with follow-up in years
  set.seed(20261105)
  n <- 2000
  group <- factor(rep(c("Treated", "Control"), each = n / 2), levels = c("Treated", "Control"))
  failure <- rexp(n, rate = ifelse(group == "Treated", 0.04, 0.06))
  censor <- runif(n, 0, 5)
  time <- pmin(failure, censor); event <- as.integer(failure <= censor)
  cum_incidence_png(time, event, group, "img/demo_cum_incidence.png", times = 0:5)
  script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
  source(file.path(dirname(normalizePath(script)), "table_grob.R"))
  table_png(cum_incidence_diff(time, event, group, 1:5), "img/demo_cum_incidence_diff.png",
            notes = "Made-up data; independent-group Wald CI.")
  cat("wrote img/demo_cum_incidence.png\nwrote img/demo_cum_incidence_diff.png\n")
}
