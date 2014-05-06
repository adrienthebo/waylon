/* waylon.js
 * Implements the JS, jQuery, and AJAX necessary for the radiator view pages.
 *
 * Usage:
 *      var settings = {
 *          refresh_interval: 30,
 *          datasource:       '/view/:name/data',
 *      };
 *      waylon.init(settings);
 */

var waylon = {
    // Allow configuration to be passed-in from the erb template.
    init: function(settings) {
        waylon.config = { };
        $.extend(waylon.config, settings);
        $(document).ready(waylon.setup());
    },

    // Setup the Waylon routine once the document is ready.
    // Repeat every 'refresh_interval' seconds.
    setup: function() {
        refreshInterval = waylon.config.refresh_interval * 1000;
        waylon.refreshRadiator()
        setInterval(waylon.refreshRadiator, refreshInterval);
    },

    // Return the image of the day for nirvana mode
    imageOfTheDay: function() {
        date = new Date();
        day = date.getDay();
        result = "/img/img0" + day + ".png";
        return result;
    },

    // Enter nirvana mode
    nirvanaBegin: function() {
        $('body').addClass('nirvana');
        $('body').css('background-image', 'url('+ waylon.imageOfTheDay() + ')');
        $('#radiator').hide();
    },

    // Exit nirvana mode
    nirvanaEnd: function() {
        $('body').removeClass('nirvana');
        $('body').css('background-image', 'none');
        $('#radiator').show();
    },

    // Poll '/view/:name/data' to fetch the latest data from Jenkins,
    // starting and ending Nirvana mode as needed.
    refreshRadiator: function() {
        $(document).ajaxSend(function() {
            $('#loading').show();
        });
        $(document).ajaxComplete(function () {
            $('#loading').hide();

            // This needs to be done after the elements have already loaded.
            // Therefore, it's safe to put it in ajaxComplete
            $('[data-toggle="tooltip"]').tooltip({'placement': 'bottom'});

            // Nirvana mode
            if(($('.building-job').length == 0) &&
                ($('.failed-job').length == 0) &&
                ($('.alert-danger').length == 0)) {
                waylon.nirvanaBegin();
            }
            else {
                waylon.nirvanaEnd();
            }
        });

        // Do it.
        $('#radiator').load(waylon.config.datasource);
    },
};
