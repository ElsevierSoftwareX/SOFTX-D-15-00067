#-------------------------------------------------------------------------------
# FLCatchExt - Extension of original FLCatch object, it includes 2 new slots:
# alpha and beta: Coob-Douglas function parameters.
#
# Dorleta Garcia - Azti Tecnalia - 21/07/2010
#   Change: 06/06/2011 (dga) extend FLCatch to make flexible quant dimension in alpha, beta and catch.q.
#-------------------------------------------------------------------------------

## FLCatchExt               {{{
validFLCatchExt <- function(object)
{
    names <- names(getSlots('FLCatchExt')[getSlots('FLCatchExt')=="FLQuant"])
    nits  <- sort(unique(unlist(qapply(object, function(x) dims(x)$iter))))

  if (length(nits)>2) return(paste("All FLQuant must either have same number of iters or '1 & n'"))

	for(i in names)
	{
		# all dimnames but iter, age and unit are the same
		if(!identical(unlist(dimnames(object@landings.n)[c(2,4:5)]),
			unlist(dimnames(slot(object, i))[c(2,4:5)])))
			return(paste('All elements must share dimensions 2,4 and 5: Error in FLCatchExt', i))
	}
	for (i in names[!names%in%c('landings', 'discards', 'catch.q', 'alpha', 'beta')])
	{
		# quant is n
		if(!identical(unlist(dimnames(object@landings.n)[1]),
			unlist(dimnames(slot(object, i))[1])))
			return(paste('All elements must share quant names: Error in FLCatchExt', i))
	}

	for (i in c('alpha', 'beta', 'catch.q'))
	{
		# quant is n
		if(!identical(unlist(dimnames(object@alpha)), unlist(dimnames(slot(object, i)))))
			return('"alpha", "beta" and "catch.q" must share dimensions: Error in FLCatchExt')
	}
	# alpha, beta and catch.q have the same dimensions, check that alpha has correct dimension in quant.
#	if(dim(object@alpha)[3] > 1 & dim(object@alpha)[3] != dim(object@alpha)[4]) return('Wrong unit dimension for "alpha", "beta" and "catch.q"')
	if(dim(object@alpha)[1] > 1 & dim(object@alpha)[1] != dim(object@landings.n)[1]) return('Wrong quant dimension for "alpha", "beta" and "catch.q"')

	for (i in c('landings', 'discards'))
	{
		# quant is 1
		if(any(dim(slot(object, i))[c(1,3,5)] != 1))
			return(paste('Wrong dimensions for slot ', i, 'in FLCatchExt'))
	}
	return(TRUE)
}

setClass("FLCatchExt",
    representation(
		'FLComp',
            landings    = "FLQuant", landings.n   = "FLQuant",
            landings.wt = "FLQuant", landings.sel = "FLQuant",
            discards    = "FLQuant", discards.n   = "FLQuant",
            discards.wt = "FLQuant", discards.sel = "FLQuant",
            catch.q     = "FLQuant", price        = "FLQuant",
            alpha       = "FLQuant", beta         = "FLQuant"),
    prototype=prototype(
		name		= character(0),
		desc		= character(0),
	  range       = as.numeric(c(min=NA, max=NA, plusgroup=NA,
			minyear=NA, maxyear=NA)),
    landings = new("FLQuant"), landings.n = new("FLQuant"),
    landings.wt = new("FLQuant"), landings.sel = new("FLQuant"),
    discards = new("FLQuant"), discards.n  = new("FLQuant"),
    discards.wt = new("FLQuant"), discards.sel= new("FLQuant"),
    catch.q     = new("FLQuant"), price = new("FLQuant"),
    alpha = new("FLQuant"), beta = new("FLQuant")),
	validity=validFLCatchExt
)
remove(validFLCatchExt) # }}}


# FLCatchExt()                {{{
setGeneric('FLCatchExt', function(object, ...)
		standardGeneric('FLCatchExt'))

# TODO Fix size of input objects and validity
setMethod('FLCatchExt', signature(object='FLQuant'),
	function(object, range='missing', name='NA', desc=character(0), ...) {
		# initial objects
		flq <- FLQuant(NA, dimnames=dimnames(object))
		flqa <- quantSums(flq)
		flqau <- unitSums(quantSums(flq))
		dims <- dims(flq)
		args <- list(...)

    # construct range
		if(missing(range))
			range <- c(min=dims$min, max=dims$max, plusgroup=NA,
				minyear=dims$minyear, maxyear=dims$maxyear)

		# output object
		res <- new('FLCatchExt', range=range, name=name, desc=desc,
			landings.n=flq, landings.wt=flq, landings.sel=flq, landings=flqau,
			discards.n=flq, discards.wt=flq, discards.sel=flq, discards=flqau,
			catch.q=flq, price=flq, alpha = flq, beta = flq)
		# Load given slots
		for(i in names(args))
			slot(res, i) <- args[[i]]
		return(res)
	}
)
setMethod('FLCatchExt', signature(object='missing'),
	function(...)
  {
		# get arguments & select first full FLQuant
		args <- list(...)
		args <- args[lapply(args, class) == 'FLQuant']

		flqs <- args[!(names(args) %in% c('landings', 'discards'))]

		# select full flquant, or small flquant, or create dimnames
		if(length(flqs) > 0)
			dimnames <- dimnames(flqs[[1]])
		else if(length(args) > 0)
			dimnames <- dimnames(args[[1]])
		else
			dimnames <- dimnames(FLQuant())
		return(FLCatchExt(FLQuant(dimnames=dimnames), ...))
	}
)	# }}}


## computeLandings	{{{
setMethod("computeLandings", signature(object="FLCatchExt"),
	function(object, na.rm=TRUE) {
        res <- quantSums(landings.n(object)*landings.wt(object), na.rm=na.rm)
        units(res) <- paste(units(landings.n(object)), units(landings.wt(object)))
        return(res)
 	}
)	# }}}

## computeDiscards	{{{
setMethod("computeDiscards", signature(object="FLCatchExt"),
	function(object, na.rm=TRUE) {
        res <- quantSums(discards.n(object)*discards.wt(object), na.rm=na.rm)
        units(res) <- paste(units(discards.n(object)), units(discards.wt(object)))
        return(res)
 	}
)	# }}}

# '['       {{{
setMethod('[', signature(x='FLCatchExt'),
	function(x, i, j, k, l, m, n, ..., drop=FALSE)
  {
    dn <- dimnames(landings.n(x))

		if (missing(i))
			i  <-  seq(1, length(dn[1][[1]]))
		if (missing(j))
			j  <-  dn[2][[1]]
   	if (missing(k))
   		k  <-  dn[3][[1]]
		if (missing(l))
			l  <-  dn[4][[1]]
		if (missing(m))
			m  <-  dn[5][[1]]
		if (missing(n))
			n  <-  dn[6][[1]]

    # catch.q  dim[1] = 1 => dim[4] = 1
    if(dim(slot(x, 'catch.q'))[1] == 1)
      slot(x, 'catch.q') <- slot(x, 'catch.q')[1,j,k,1,m,n, drop=FALSE]
    else
      slot(x, 'catch.q') <- slot(x, 'catch.q')[i,j,k,1,m,n, drop=FALSE]

    # full quants
	  quants <- list("landings.n", "landings.wt", "landings.sel",
      "discards.n","discards.wt","discards.sel","price")
    for(q in quants)
      slot(x, q) <- slot(x, q)[i,j,k,l,m,n, drop=FALSE]

    # no-quant quants
	  quants <- list("landings", "discards", "alpha", "beta")
    for(q in quants)
      slot(x, q) <- slot(x, q)[1,j,k,1,m,n, drop=FALSE]

    # range
    x@range['min'] <- as.numeric(dn[[1]][1])
    x@range['max'] <- as.numeric(dn[[1]][length(dn[[1]])])
    x@range['minyear'] <- as.numeric(dn[[2]][1])
    x@range['maxyear'] <- as.numeric(dn[[2]][length(dn[[2]])])

    return(x)
  }
)   # }}}

## "[<-"            {{{
setMethod("[<-", signature(x="FLCatch", value="FLCatch"),
	function(x, i, j, k, l, m, n, ..., value)
	{
    dn <- dimnames(landings.n(x))

		if (missing(i))
			i  <-  dn[1][[1]]
		if (missing(j))
			j  <-  dn[2][[1]]
   	if (missing(k))
   			k  <-  dn[3][[1]]
		if (missing(l))
			l  <-  dn[4][[1]]
		if (missing(m))
			m  <-  dn[5][[1]]
		if (missing(n))
			n  <-  dn[6][[1]]

	  quants <- list("catch.q", "landings.n", "landings.wt", "landings.sel",
      "discards.n","discards.wt","discards.sel","price")
    for(q in quants)
      slot(x, q)[i,j,k,l,m,n] <- slot(value, q)

    quants <- list("landings", "discards", "alpha", "beta")
    for(q in quants)
      slot(x, q)[1,j,k,l,m,n] <- slot(value,q)

 		return(x)
	}
)   # }}}


# addFLCatch
setGeneric('addFLCatch', function(e1, e2, ...)
		standardGeneric('addFLCatch'))

# catchNames
setGeneric('catchNames', function(object, ...)
		standardGeneric('catchNames'))
setGeneric('catchNames<-', function(object, ..., value)
		standardGeneric('catchNames<-'))
		
# addFLCatch for FLCatch {{{
setMethod('addFLCatch', signature(e1='FLCatchExt', e2='FLCatchExt'),
  function(e1, e2)
  {
    # add
    qnames <- c('landings', 'landings.n', 'discards', 'discards.n')
    for(i in qnames)
      slot(e1, i) <- slot(e1, i) + slot(e2, i)
    # mean weighted by catch
    qnames <- c('landings.sel', 'discards.sel')
    for(i in qnames)
      slot(e1, i) <- slot(e1, i) + slot(e2, i)
    # mean weighted by effshare
    return(e1)
  }
) # }}}

# setPlusGroup  {{{
setMethod('setPlusGroup', signature(x='FLCatchExt', plusgroup='numeric'),
	function(x, plusgroup, na.rm=FALSE)
	{
	#check plusgroup valid
	if (!missing(plusgroup))
     x@range["plusgroup"]<-plusgroup
  if(x@range["plusgroup"] > x@range["max"])
		 return("Error : plus group greater than oldest age")

  pg.range <- as.character(x@range["max"]:x@range["plusgroup"])

	for (i in c("landings.wt", "landings.sel", "price"))
     slot(x,i)[as.character(x@range["plusgroup"])]<-quantSums(slot(x,i)[pg.range]*x@landings.n[pg.range])/quantSums(x@landings.n[pg.range])

	for (i in c("discards.wt", "discards.sel"))
     slot(x,i)[as.character(x@range["plusgroup"])]<-quantSums(slot(x,i)[pg.range]*x@discards.n[pg.range])/quantSums(x@discards.n[pg.range])

  x@landings.n[as.character(x@range["plusgroup"])]<-quantSums(x@landings.n[pg.range])
  x@discards.n[as.character(x@range["plusgroup"])]<-quantSums(x@discards.n[pg.range])

  x<-x[as.character(x@range["min"]:x@range["plusgroup"])]

  x@range["max"]<-x@range["plusgroup"]

	return(x)
	}
)# }}}

# catchNames {{{
setMethod('catchNames', signature(object='FLCatchExt'),
  function(object)
    return(object@name))

setReplaceMethod('catchNames', signature(object='FLCatchExt', value='character'),
  function(object, value)
  {
    object@name <- value
    return(object)
  }
) # }}}

## trim     {{{
setMethod("trim", signature("FLCatchExt"), function(x, ...){

	args <- list(...)

  rng<-range(x)


  c1 <- args[[quant(x@landings.n)]]
	c2 <- args[["year"]]
	c3 <- args[["unit"]]
	c4 <- args[["season"]]
	c5 <- args[["area"]]
	c6 <- args[["iter"]]

  # FLQuants with quant
  names <- getSlotNamesClass(x, 'FLQuant')
  for (name in names)
  {
    if(name %in% c('landings', 'discards'))
      slot(x,name) <- trim(slot(x,name), year=c2, unit=c3, season=c4,
        area=c5, iter=c6)
        
    if(name %in% c('alpha', 'beta'))
      slot(x,name) <- trim(slot(x,name), year=c2, season=c4,
        area=c5, iter=c6)
    # catch.q
    else if(name == 'catch.q')
    {
      if(dim(slot(x, 'catch.q'))[1] == 1)
        slot(x, 'catch.q') <- trim(slot(x, 'catch.q'), year=c2,
          season=c4, area=c5, iter=c6)
      else
        slot(x, 'catch.q') <- trim(slot(x, 'catch.q'), ...)
    }
    else
    {
      slot(x,name) <- trim(slot(x,name), ...)
    }
  }

  # range
  if (length(c1) > 0) {
    x@range["min"] <- c1[1]
    x@range["max"] <- c1[length(c1)]
    if (rng["max"] != x@range["max"])
        x@range["plusgroup"] <- NA
  }
  if (length(c2)>0 ) {
    x@range["minyear"] <- c2[1]
    x@range["maxyear"] <- c2[length(c2)]
  }
	return(x)

}) # }}}

# catch et al {{{
# catch
setMethod('catch', signature(object='FLCatchExt'),
  function(object)
  {
    res <- landings(object) + discards(object)
    if (units(discards(object)) == units(landings(object)))
		  units(res) <- units(discards(object))
    else
      warning("units of discards and landings do not match")
    return(res)
  }
)

# catch.n
setMethod('catch.n', signature(object='FLCatchExt'),
  function(object)
  {
    res <- landings.n(object) + discards.n(object)
    if (units(discards.n(object)) == units(landings.n(object)))
		  units(res) <- units(discards.n(object))
    else
      warning("units of discards.n and landings.n do not match")
    return(res)
  }
)

# catch.wt
setMethod('catch.wt', signature(object='FLCatchExt'),
  function(object, method='n')
  {
    if(method == 'n')
    {
      idx <- landings.n(object) + discards.n(object)
      idx[idx == 0]  <- 1

      res <- (landings.wt(object) * landings.n(object) +
          discards.wt(object) * discards.n(object)) / idx
    } else if (method == 'sel')
    {
      idx <- landings.sel(object) + discards.sel(object)
      idx[idx == 0]  <- 1
      res <- (landings.wt(object) * landings.sel(object) +
          discards.wt(object) * discards.sel(object)) / idx
    }
    if (units(discards.wt(object)) == units(landings.wt(object)))
				units(res) <- units(discards.wt(object))
    return(res)
  }
)

# catch.sel
setMethod('catch.sel', signature(object='FLCatchExt'),
  function(object)
  {
    return(landings.sel(object) + discards.sel(object))
  }
) # }}}
