/**
 * tools.js - Copyright(C) 2021 Donald Zou 
 */

$(".ip_dropdown").on("change", function () {
    $(".modal.show .btn").removeAttr("disabled");
});

$(".conf_dropdown").on("change", function () {
    const $ipDropdown = $(".modal.show .ip_dropdown");
    $ipDropdown.html('<option value="none" selected="selected" disabled>Loading...</option>');
    $.ajax({
        url: "/get_ping_ip",
        method: "POST",
        data: { config: $(this).children("option:selected").val() },
        success: function (res) {
            $ipDropdown.html('<option value="none" selected="selected" disabled>Choose an IP</option>');
            $ipDropdown.append(res);
        },
        error: function () {
            $ipDropdown.html('<option value="none" selected="selected" disabled>Error loading IPs</option>');
        }
    });
});

// Ping Tools
$(".send_ping").on("click", function () {
    const $this = $(this);
    const $pingModal = $("#ping_modal");
    const $formControls = $pingModal.find(".form-control");
    const $pingResult = $(".ping_result tbody");

    $this.attr("disabled", "disabled").html("Pinging...");
    $formControls.attr("disabled", "disabled");

    $.ajax({
        method: "POST",
        url: "/ping_ip",
        data: {
            ip: $(":selected", $pingModal.find(".ip_dropdown")).val(),
            count: $pingModal.find(".ping_count").val()
        },
        success: function (res) {
            $pingResult.html(`
                <tr><th scope="row">Address</th><td>${res.address}</td></tr>
                <tr><th scope="row">Is Alive</th><td>${res.is_alive}</td></tr>
                <tr><th scope="row">Min RTT</th><td>${res.min_rtt}ms</td></tr>
                <tr><th scope="row">Average RTT</th><td>${res.avg_rtt}ms</td></tr>
                <tr><th scope="row">Max RTT</th><td>${res.max_rtt}ms</td></tr>
                <tr><th scope="row">Package Sent</th><td>${res.package_sent}</td></tr>
                <tr><th scope="row">Package Received</th><td>${res.package_received}</td></tr>
                <tr><th scope="row">Package Loss</th><td>${res.package_loss}</td></tr>
            `);
        },
        error: function () {
            $pingResult.html('<tr><td colspan="2" class="text-danger">Error occurred while pinging.</td></tr>');
        },
        complete: function () {
            $this.removeAttr("disabled").html("Ping");
            $formControls.removeAttr("disabled");
        }
    });
});