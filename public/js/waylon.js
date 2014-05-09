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
    init: function (settings) {
        'use strict';
        waylon.config = { };
        $.extend(waylon.config, settings);
        $(document).ready(waylon.setup());
    },

    // Setup the Waylon routine once the document is ready.
    // Repeat every 'refresh_interval' seconds.
    setup: function () {
        'use strict';
        var refreshInterval = waylon.config.refresh_interval * 1000;
        waylon.refreshRadiator();
        setInterval(waylon.refreshRadiator, refreshInterval);
    },

    // Return the image of the day for nirvana mode
    imageOfTheDay: function () {
        'use strict';
        var date = new Date(),
            day = date.getDay(),
            result = "/img/img0" + day + ".png";
        return result;
    },

    // Nirvana mode enablement. Checks for the number of elements on the
    // page belonging to any of the classes listed in elems[]. If any are
    // found, returns false.
    nirvanaCheck: function () {
        'use strict';
        var bad_elems  = ['.building-job', '.failed-job', '.alert-danger', '.alert-warning'],
            good_elems = [ '.successful-job' ],
            bad_count  = 0,
            good_count = 0;

        $.each(bad_elems, function (i, elem) {
            bad_count += $(elem).length;
        });

        $.each(good_elems, function (i, elem) {
            good_count += $(elem).length;
        });

        if ((bad_count === 0) && (good_count >= 1)) {
            return true;
        }
        else {
            return false;
        }
    },

    // Enter nirvana mode
    nirvanaBegin: function () {
        'use strict';
        $('body').addClass('nirvana');
        $('body').css('background-image', 'url(' + waylon.imageOfTheDay() + ')');
        $('#radiator').hide();
    },

    // Exit nirvana mode
    nirvanaEnd: function () {
        'use strict';
        $('body').removeClass('nirvana');
        $('body').css('background-image', 'none');
        $('#radiator').show();
    },

    // Poll '/view/:name/data' to fetch the latest data from Jenkins,
    // starting and ending Nirvana mode as needed.
    refreshRadiator: function () {
        'use strict';
        $(document).ajaxSend(function () {
            $('#loading').show();
        });
        $(document).ajaxComplete(function () {
            $('#loading').hide();

            // This needs to be done after the elements have already loaded.
            // Therefore, it's safe to put it in ajaxComplete
            $('[data-toggle="tooltip"]').tooltip({'placement': 'bottom'});

            // Nirvana mode
            var isNirvana = waylon.nirvanaCheck();
            if (isNirvana) {
                waylon.nirvanaBegin();
            }
            else {
                waylon.nirvanaEnd();
            }
        });

        // Do it.
        $('#radiator').load(waylon.config.datasource);
    }
};
