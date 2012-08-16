$('.dropdown-toggle').dropdown();
$(".alert").alert();
$('.typeahead').typeahead();


$("#cities").typeahead({
    source: function(typeahead, query) {
        if(this.ajax_call)
            this.ajax_call.abort();
        this.ajax_call = $.ajax({
            dataType : 'json',
            data: {
                q: query
            },
            url: $("#cities").data('source'),
            success: function(data) {
                typeahead.process(data);
            }
        });
    },
    property: 'name',
    onselect: function (obj) {
        $("#city_id").val(obj.id)
        console.log(obj);
    }
});

$("#regions").typeahead({
    source: function(typeahead, query) {
        if(this.ajax_call)
            this.ajax_call.abort();
        this.ajax_call = $.ajax({
            dataType : 'json',
            data: {
                q: query
            },
            url: $("#regions").data('source'),
            success: function(data) {
                typeahead.process(data);
            }
        });
    },
    property: 'name',
    onselect: function (obj) {
        $("#region_id").val(obj.id)
        console.log(obj);
    }
});

$("#countries").typeahead({
    source: function(typeahead, query) {
        if(this.ajax_call)
            this.ajax_call.abort();
        this.ajax_call = $.ajax({
            dataType : 'json',
            data: {
                q: query
            },
            url: $("#countries").data('source'),
            success: function(data) {
                typeahead.process(data);
            }
        });
    },
    property: 'name',
    onselect: function (obj) {
        $("#country_id").val(obj.id)
        console.log(obj);
    }
});