#
# Parameters are obtained from a "data-params" attribute on the ad container. All parameters that are required for
# functionality have defaults so a "data-params" attribute is not required for the script to function. The "p" object
# defines all parameter values that are useful and as such can be used as a reference for possible "data-params" vaules.
#
# USE:
#  <div class="advertisement" data-require="ads" data-options='{"site_name": "ngc", "zone": "American Weed", "width": "300", "height": "600" }>
#  </div>
#
# jq.ads provides some syntactic sugar useful if one is unfamiliar with DART ad calls. The data-options attribute can take standard DART parameters and it can also take a more
#      verbose syntax. In cases where both the standard DART parameter and a corresponding verbose syntax exist, the verbose option will win.

$ = jQuery
plugin = 'ads'
ad_count = 0
settings = 
    srcdoc: ''
    fallback: ''
    
    pushdown : false
    refreshable: false

    # DoubleClick parameters
    dcopt : '' #designates ad as an intersticial. Gets overwritten by is_intersticial if it is set.
    height : '' # In pixles
    is_intersticial: undefined # boolean. Overwrites dcopt parameter if set
    kw: $('meta[name="keywords"]').attr('content'), #key words. Defaults to keywords from pages' meta tag
    publisher: 'ng' # DoubleClick publisher identifier
    site_name : '' # Channel level categorization at NGS
    sz : '300x250' # Gets overwritten if height and/or width is set
    tile: ''  # defualts to index of ad element in collection
    topic: '' # horizontal taging accross verticals
    sbtpc: '' # sub topics
    slot: ''  # A named identifier for a given ad location
    width: '' # In pixles
    zone : '' # Ad Zone. Effectively the subsection
    zone_suffix: '' #NGS appends an identifier to zone for duplicate ad sizes in same zone
    
methods = 
    init: (options) ->

        return @.each () ->
            
            $this = $(this)
            data = $this.data plugin
            parameters = {}
            path = window.location.pathname.split '/'

            if not data
                opts = $.extend {}, settings, options
                data = {}

                #setup
                data.ad_count = ad_count
                size = opts.sz.split 'x'
                size[0] = opts.width if opts.width isnt ''
                size[1] = opts.height if opts.height isnt ''
                size = size.join 'x'

                #build double click parameters from options. Only build what is going to be used.
                parameters.dcopt        = if opts.is_intersticial isnt undefined then opts.is_intersticial else opts.dcopt
                #parameters.dcopt       = if not opts.dcopt and ad_count is 0 then 'ist' else ''
                parameters.kw           = opts.kw
                parameters.publisher    = opts.publisher
                parameters.site_name    = if opts.site_name isnt '' then opts.site_name else (if path[1] and path[1] isnt 'channel' then path[1] else 'ngc') #defaults to whatever the "bookend" is or 'ngc'
                parameters.tile         = if opts.tile is '' then ad_count else opts.tile
                parameters.topic        = opts.topic if opts.topic isnt ''
                parameters.sbtpc        = opts.sbtpc if opts.sbtpc isnt ''
                parameters.slot         = opts.slot if opts.slot isnt ''
                parameters.sz           = size
                parameters.zone         = "#{ (if path.length > 3 then path[2] else 'homepage') if not opts.zone }#{ opts.zone_suffix }"

                data.options    = opts
                data.ad_params  = parameters

                $this.data plugin, data

                $.fn[plugin].$refreshables.push this if opts.refreshable

                # paramClone = $.extend {}, parameters # we don't want any changes made by loadAd affecting parameters object.
                # methods.loadAd.call $this[0], paramClone

                ad_count += 1
                #events
                $(window).on 'stateChange', (e) ->
                    $refreshables = $.fn[plugin].$refreshables
                    window.clearTimeout $.fn[plugin].timer
                    $.fn[plugin].timer = window.setTimeout ->
                        $refreshables.ads()
                    , 500

            params = $.extend {}, data?.ad_params
            methods.loadAd.call $this[0], params
                    
    loadAd: (params) ->
        $this   = $ @
        data    = $this.data plugin
        opts    = data.options

        # URI builder
        ad_base     = 'http://ad.doubleclick.net/ad'
        ad_img      = "#{ ad_base }/"
        ad_iframe   = "#{ ad_base }i/"
        ad_js       = "#{ ad_base }j/"
        
        # doc frags
        adFrame     = document.createElement 'iframe'
        $adFrame    = $ adFrame
        unWrapped   = document.createElement 'script'
        
        # Add generated items to be serialized
        params.ord = Math.floor 1000000 * Math.random() #used for cache-busting

        # Store an remove items that shouldn't be serialized
        publisher = params.publisher
        delete params.publisher
        
        site_name = params.site_name
        delete params.site_name

        zone = params.zone
        delete params.zone
        

        frame_id = 'ad_frame' + data.ad_count
        tile     = data.ad_count #used to specify the order of an ad slot on a webpage

        $adFrame.attr
            width: '100%'
            height: params.sz.split('x')[1]
            allowtransparency : true
            #sandbox : 'allow-scripts'
            id: frame_id
            name: frame_id
            seamless: true
            frameborder: 0
            src: "#{ ad_iframe }#{ publisher }.#{ site_name }/#{ zone };#{ serialize params }"
        
        if opts.pushdown
            unWrapped.src = ad_js + serialize params
            ad = unWrapped
        else
            try
                $adFrame.html fallback
            catch err
            ad = $adFrame

        $this.html ad

serialize = (obj) ->
    params = for key, val of obj
        "#{key}=#{encodeURI val}"

    return params.join ';'

        
$.fn[plugin] = ( method ) ->
    if methods[method]
        methods[method].apply this, Array.prototype.slice.call( arguments, 1 )
    else if typeof method is 'object' or not method 
        methods.init.apply this, arguments
    else
        $.error "Method #{ method } does not exist on jQuery.#{ plugin }"

$.fn[plugin].$refreshables = $()
$.fn[plugin].timer = undefined