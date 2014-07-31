var ex = {

    config: {
        refresh_interval: 60
    },

    // Allow configuration to be passed-in from the erb template.
    init: function (settings) {
        'use strict';
        $.extend(ex.config, settings);
        $(document).ready(ex.setup());
    },

    setup: function() {
        'use strict';
        ex.refreshRadiator();

        var refreshInterval = ex.config.refresh_interval * 1000;
        setInterval(ex.refreshRadiator, refreshInterval);
    },

    refreshRadiator: function() {
        'use strict';

        var url = "/api/view/" + ex.config.view + "/server/" + ex.config.server + ".json";

        $('#loading').show();
        $.ajax({
            url: url,
            type: "GET",
            dataType: "json",

            success: function(json) {
                ex.buildJobs(json);
            },

            complete: function() {
                // This needs to be done after the elements have already loaded.
                // Therefore, it's safe to put it in ajaxComplete
                // ???
                $('[data-toggle="tooltip"]').tooltip({'placement': 'bottom'});
                $('#loading').hide();
            },
        });
    },

    buildJobs: function(json) {
        'use strict';
        $("#jobs").empty();
        $.each(json.jobs, function(i, item) {
            var tr = $("<tr>").append(
                $("<td>").text(item),
                $("<td>").text("unknown")
            );
            tr.addClass("unknown-job");
            tr.attr("status", "unknown-job");
            $("#jobs").append(tr);
            ex.populateJob(ex.config.view, ex.config.server, item, tr);

        });
    },


    populateJob: function(view, server, job, e) {
        'use strict';
        var url = "/api/view/" + view + "/server/" + server + "/job/" + job + ".json";

        $.ajax({
            url: url,
            type: "GET",
            dataType: "json",
            success: function(json) {
                e.empty();

                var link = $("<a>").attr("href", json["url"]).text(job);

                e.append(
                    $("<td>").html(link),
                    $("<td>").text(json["status"])
                );

                var stat;
                switch(json["status"]) {
                    case "running":
                        stat = "building-job";
                        break;
                    case "failure":
                        stat = "failed-job";
                        break;
                    case "success":
                        stat = "successful-job";
                }

                if(stat) {
                    e.removeClass("unknown-job");
                    e.addClass(stat);
                    e.attr("status", stat);
                }
            }
        });
    },
};
