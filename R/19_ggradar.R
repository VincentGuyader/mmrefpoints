#' Radar plot
#' @details I modified the `ggradar()` function slightly to do nice things that I like, like use a custom color palette, including different line types, etc.
#'
#' @param plot.data a dataframe with performance measures as columns and management scenarios as rows
#' @param axis.labels a vector of names for the performance measures
#' @param grid.label.size a numeric value for grid label size
#' @param axis.label.size a numeric value for axis label size
#' @param plot.legend logical; whether or not to plot a legend to the right of the plot
#' @param legend.text.size numeric value for size of legend text
#' @param palette.vec a vector of colors to use for the different scenarios (each row = 1 color)
#' @param manual.levels a vector if you want to manually set factor levels
#'
#' @author Ricardo Bion, modified slightly by Margaret Siple
#' @details Since this code was originally written, ggradar has becomes its own standalone package. For more information and for the most current version of the function, see Ricardo Bion's \href{https://github.com/ricardo-bion/ggradar/}{GitHub}
#'
#' @export

ggradar <- function(plot.data,
                    axis.labels = colnames(plot.data)[-1],
                    grid.label.size = 7,
                    axis.label.size = 8,
                    plot.legend = if (nrow(plot.data) > 1) TRUE else FALSE,
                    legend.text.size = grid.label.size,
                    palette.vec = c("#D53E4F", "#FC8D59", "#FEE08B", "#E6F598", "#99D594", "#3288BD"),
                    manual.levels = NA) {
  #library(ggplot2)

  # settings (originally these were function options; I have hard coded them here)
  font.radar <- "Circular Air Light"
  values.radar <- c("0", "", "1")
  plot.data <- as.data.frame(plot.data)
  grid.min <- 0
  grid.mid <- 0.5
  grid.max <- 1
  centre.y <- grid.min - ((1 / 9) * (grid.max - grid.min))
  plot.extent.x.sf <- 1
  plot.extent.y.sf <- 1.2
  x.centre.range <- 0.02 * (grid.max - centre.y)
  label.centre.y <- FALSE
  grid.line.width <- 0.5
  gridline.min.linetype <- "longdash"
  gridline.mid.linetype <- "longdash"
  gridline.max.linetype <- "longdash"
  gridline.min.colour <- "grey"
  gridline.mid.colour <- "#007A87"
  gridline.max.colour <- "grey"
  gridline.label.offset <- -0.1 * (grid.max - centre.y)
  label.gridline.min <- TRUE
  axis.label.offset <- 1.15
  axis.line.colour <- "grey"
  group.line.width <- 1.5
  group.point.size <- 4
  background.circle.colour <- "#D7D6D1"
  background.circle.transparency <- 0.2
  legend.title <- ""

  plot.data[, 1] <- as.factor(as.character(plot.data[, 1]))
  if (all(!is.na(manual.levels))) {
    plot.data[, 1] <- factor(plot.data[, 1], levels = manual.levels)
  }
  names(plot.data)[1] <- "group"

  var.names <- colnames(plot.data)[-1] #' Short version of variable names
  # axis.labels [if supplied] is designed to hold 'long version' of variable names
  # with line-breaks indicated using \n

  # caclulate total plot extent as radius of outer circle x a user-specifiable scaling factor
  plot.extent.x <- (grid.max + abs(centre.y)) * plot.extent.x.sf
  plot.extent.y <- (grid.max + abs(centre.y)) * plot.extent.y.sf

  # Check supplied data makes sense
  if (length(axis.labels) != ncol(plot.data) - 1) {
    return("Error: 'axis.labels' contains the wrong number of axis labels")
  }
  if (min(plot.data[, -1]) < centre.y) {
    return("Error: plot.data' contains value(s) < centre.y")
  }
  if (max(plot.data[, -1]) > grid.max) {
    return("Error: 'plot.data' contains value(s) > grid.max")
  }
  # Declare required internal functions

  CalculateGroupPath <- function(df) {
    # Converts variable values into a set of radial x-y coordinates
    # Code adapted from a solution posted by Tony M to
    # http://stackoverflow.com/questions/9614433/creating-radar-chart-a-k-a-star-plot-spider-plot-using-ggplot2-in-r
    # Args:
    #  df: Col 1 -  group ('unique' cluster / group ID of entity)
    #      Col 2-n:  v1.value to vn.value - values (e.g. group/cluser mean or median) of variables v1 to v.n

    path <- df[, 1]

    ## find increment
    angles <- seq(from = 0, to = 2 * pi, by = (2 * pi) / (ncol(df) - 1))
    ## create graph data frame
    graphData <- data.frame(seg = "", x = 0, y = 0)
    graphData <- graphData[-1, ]

    for (i in levels(path)) {
      pathData <- subset(df, df[, 1] == i)
      for (j in c(2:ncol(df))) {
        # pathData[,j]= pathData[,j]


        graphData <- rbind(graphData, data.frame(
          group = i,
          x = pathData[, j] * sin(angles[j - 1]),
          y = pathData[, j] * cos(angles[j - 1])
        ))
      }
      ## complete the path by repeating first pair of coords in the path
      graphData <- rbind(graphData, data.frame(
        group = i,
        x = pathData[, 2] * sin(angles[1]),
        y = pathData[, 2] * cos(angles[1])
      ))
    }
    # Make sure that name of first column matches that of input data (in case !="group")
    colnames(graphData)[1] <- colnames(df)[1]
    graphData # data frame returned by function
  }
  CaclulateAxisPath <- function(var.names, min, max) {
    # Caculates x-y coordinates for a set of radial axes (one per variable being plotted in radar plot)
    # Args:
    # var.names - list of variables to be plotted on radar plot
    # min - MININUM value required for the plotted axes (same value will be applied to all axes)
    # max - MAXIMUM value required for the plotted axes (same value will be applied to all axes)
    # var.names <- c("v1","v2","v3","v4","v5")
    n.vars <- length(var.names) # number of vars (axes) required
    # Cacluate required number of angles (in radians)
    angles <- seq(from = 0, to = 2 * pi, by = (2 * pi) / n.vars)
    # calculate vectors of min and max x+y coords
    min.x <- min * sin(angles)
    min.y <- min * cos(angles)
    max.x <- max * sin(angles)
    max.y <- max * cos(angles)
    # Combine into a set of uniquely numbered paths (one per variable)
    axisData <- NULL
    for (i in 1:n.vars) {
      a <- c(i, min.x[i], min.y[i])
      b <- c(i, max.x[i], max.y[i])
      axisData <- rbind(axisData, a, b)
    }
    # Add column names + set row names = row no. to allow conversion into a data frame
    colnames(axisData) <- c("axis.no", "x", "y")
    rownames(axisData) <- seq(1:nrow(axisData))
    # Return calculated axis paths
    as.data.frame(axisData)
  }
  funcCircleCoords <- function(center = c(0, 0), r = 1, npoints = 100) {
    # Adapted from Joran's response to http://stackoverflow.com/questions/6862742/draw-a-circle-with-ggplot2
    tt <- seq(0, 2 * pi, length.out = npoints)
    xx <- center[1] + r * cos(tt)
    yy <- center[2] + r * sin(tt)
    return(data.frame(x = xx, y = yy))
  }

  ### Convert supplied data into plottable format
  # (a) add abs(centre.y) to supplied plot data
  # [creates plot centroid of 0,0 for internal use, regardless of min. value of y
  # in user-supplied data]
  plot.data.offset <- plot.data
  plot.data.offset[, 2:ncol(plot.data)] <- plot.data[, 2:ncol(plot.data)] + abs(centre.y)

  # (b) convert into radial coords
  group <- NULL
  group$path <- CalculateGroupPath(plot.data.offset)

  # (c) Calculate coordinates required to plot radial variable axes
  axis <- NULL
  axis$path <- CaclulateAxisPath(var.names, grid.min + abs(centre.y), grid.max + abs(centre.y))

  # (d) Create file containing axis labels + associated plotting coordinates
  # Labels
  axis$label <- data.frame(
    text = axis.labels,
    x = NA,
    y = NA
  )

  # axis label coordinates
  n.vars <- length(var.names)
  angles <- seq(from = 0, to = 2 * pi, by = (2 * pi) / n.vars)
  axis$label$x <- sapply(1:n.vars, function(i, x) {
    ((grid.max + abs(centre.y)) * axis.label.offset) * sin(angles[i])
  })
  axis$label$y <- sapply(1:n.vars, function(i, x) {
    ((grid.max + abs(centre.y)) * axis.label.offset) * cos(angles[i])
  })

  # (e) Create Circular grid-lines + labels
  gridline <- NULL
  gridline$min$path <- funcCircleCoords(c(0, 0), grid.min + abs(centre.y), npoints = 360)
  gridline$mid$path <- funcCircleCoords(c(0, 0), grid.mid + abs(centre.y), npoints = 360)
  gridline$max$path <- funcCircleCoords(c(0, 0), grid.max + abs(centre.y), npoints = 360)

  gridline$min$label <- data.frame(
    x = gridline.label.offset, y = grid.min + abs(centre.y),
    text = as.character(grid.min)
  )
  gridline$max$label <- data.frame(
    x = gridline.label.offset, y = grid.max + abs(centre.y),
    text = as.character(grid.max)
  )
  gridline$mid$label <- data.frame(
    x = gridline.label.offset, y = grid.mid + abs(centre.y),
    text = as.character(grid.mid)
  )
  # print(gridline$min$label)
  # print(gridline$max$label)
  # print(gridline$mid$label)
  ### Start building up the radar plot

  # Delcare 'theme_clear', with or without a plot legend as required by user
  # [default = no legend if only 1 group [path] being plotted]
  theme_clear <- theme_bw(base_size = 20) +
    theme(
      axis.text.y = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      legend.key = element_rect(linetype = "blank")
    )

  if (plot.legend == FALSE) theme_clear <- theme_clear + theme(legend.position = "none")

  # Base-layer = axis labels + plot extent
  # [need to declare plot extent as well, since the axis labels don't always
  # fit within the plot area automatically calculated by ggplot, even if all
  # included in first plot; and in any case the strategy followed here is to first
  # plot right-justified labels for axis labels to left of Y axis for x< (-x.centre.range)],
  # then centred labels for axis labels almost immediately above/below x= 0
  # [abs(x) < x.centre.range]; then left-justified axis labels to right of Y axis [x>0].
  # This building up the plot in layers doesn't allow ggplot to correctly
  # identify plot extent when plotting first (base) layer]

  # base layer = axis labels for axes to left of central y-axis [x< -(x.centre.range)]
  base <- ggplot(axis$label) +
    xlab(NULL) +
    ylab(NULL) +
    coord_equal() +
    geom_text(
      data = subset(axis$label, axis$label$x < (-x.centre.range)),
      aes(x = x, y = y, label = text), size = axis.label.size, hjust = 1, family = font.radar
    ) +
    scale_x_continuous(limits = c(-1.5 * plot.extent.x, 1.5 * plot.extent.x)) +
    scale_y_continuous(limits = c(-plot.extent.y, plot.extent.y))

  # + axis labels for any vertical axes [abs(x)<=x.centre.range]
  base <- base + geom_text(
    data = subset(axis$label, abs(axis$label$x) <= x.centre.range),
    aes(x = x, y = y, label = text), size = axis.label.size, hjust = 0.5, family = font.radar
  )
  # + axis labels for any vertical axes [x>x.centre.range]
  base <- base + geom_text(
    data = subset(axis$label, axis$label$x > x.centre.range),
    aes(x = x, y = y, label = text), size = axis.label.size, hjust = 0, family = font.radar
  )
  # + theme_clear [to remove grey plot background, grid lines, axis tick marks and axis text]
  base <- base + theme_clear
  #  + background circle against which to plot radar data
  base <- base + geom_polygon(
    data = gridline$max$path, aes(x, y),
    fill = background.circle.colour,
    alpha = background.circle.transparency
  )

  # + radial axes
  base <- base + geom_path(
    data = axis$path, aes(x = x, y = y, group = axis.no),
    colour = axis.line.colour
  )


  # ... + group (cluster) 'paths'
  base <- base + geom_path(
    data = group$path, aes(x = x, y = y, group = group, colour = group),
    size = group.line.width
  )

  # ... + group points (cluster data)
  base <- base + geom_point(data = group$path, aes(x = x, y = y, group = group, colour = group), size = group.point.size)


  # ... + amend Legend title
  if (plot.legend == TRUE) base <- base + labs(colour = legend.title, size = legend.text.size)
  # ... + circular grid-lines at 'min', 'mid' and 'max' y-axis values
  base <- base + geom_path(
    data = gridline$min$path, aes(x = x, y = y),
    lty = gridline.min.linetype, colour = gridline.min.colour, size = grid.line.width
  )
  base <- base + geom_path(
    data = gridline$mid$path, aes(x = x, y = y),
    lty = gridline.mid.linetype, colour = gridline.mid.colour, size = grid.line.width
  )
  base <- base + geom_path(
    data = gridline$max$path, aes(x = x, y = y),
    lty = gridline.max.linetype, colour = gridline.max.colour, size = grid.line.width
  )
  # ... + grid-line labels (max; ave; min) [only add min. gridline label if required]
  if (label.gridline.min == TRUE) {
    base <- base + geom_text(aes(x = x, y = y, label = values.radar[1]), data = gridline$min$label, size = grid.label.size, hjust = 1, family = font.radar)
  }
  base <- base + geom_text(aes(x = x, y = y, label = values.radar[2]), data = gridline$mid$label, size = grid.label.size, hjust = 1, family = font.radar)
  base <- base + geom_text(aes(x = x, y = y, label = values.radar[3]), data = gridline$max$label, size = grid.label.size, hjust = 1, family = font.radar)
  # ... + centre.y label if required [i.e. value of y at centre of plot circle]
  if (label.centre.y == TRUE) {
    centre.y.label <- data.frame(x = 0, y = 0, text = as.character(centre.y))
    base <- base + geom_text(aes(x = x, y = y, label = text), data = centre.y.label, size = grid.label.size, hjust = 0.5, family = font.radar)
  }

  base <- base + theme(legend.key.width = unit(3, "line")) + theme(text = element_text(
    size = 20,
    family = font.radar
  )) +
    scale_colour_manual(values = rep(palette.vec, 100)) +
    theme(text = element_text(family = font.radar)) +
    theme(legend.title = element_blank())
  if (plot.legend == TRUE) {
    base <- base + theme(legend.text = element_text(size = legend.text.size * 3), legend.position = "right") +
      theme(
        legend.key.height = unit(2, "line")
        # ,plot.margin = unit(rep(10,4), "cm") # this doesn't do anything...
        # ,plot.background = element_blank()
        , plot.margin = margin(rep(0, times = 4), unit = "cm")
      )
  }

  return(base)
}



# TESTING -----------------------------------------------------------------
# plot.proj()
# lh.params.test <- list(S0 = 0.944,S1plus = 0.990,AgeMat = 17,PlusGroupAge = 25,fmax=0.29,z=2.39,lambdaMax = 1.04,K1plus=9000) #bowhead params
#
# InitDepl.vec <- rev(c(min(1,0.5*1.25),
#                       0.5,
#                       0.5*.75))
# testing.list <- list()
# for(i in 1:3){
#   aa <- Projections(NOut = 50, #low bycatch
#                     #ConstantBycatch=list(Catch=50,CV=0.5),
#                     ConstantRateBycatch = list(Rate=0.01,CV=0.8),
#                     InitDepl = InitDepl.vec[i],
#                     lh.params = lh.params.test,
#                     nyears = 100
#   )
#   bb <- Projections(NOut = 50, #med bycatch
#                     #ConstantBycatch=list(Catch=100,CV=0.5),
#                     ConstantRateBycatch = list(Rate=0.1,CV=0.75),
#                     InitDepl = InitDepl.vec[i],
#                     lh.params = lh.params.test,
#                     nyears = 100)
#   cc <- Projections(NOut = 50, #high bycatch
#                     #ConstantBycatch=list(Catch=200,CV=0.5),
#                     ConstantRateBycatch = list(Rate=0.2,CV=0.75),
#                     InitDepl = InitDepl.vec[i],
#                     lh.params = lh.params.test,
#                     nyears = 100)
#   testing.list [[i]] <- list(aa,bb,cc) # aa is the lowest bycatch rate; testing.list[[1]] contains the lowest depletion level
# }
# plot.proj(high = cc,med = bb,low = aa,spaghetti = 3)


# Plot a few different starting depletions to test plot.proj
