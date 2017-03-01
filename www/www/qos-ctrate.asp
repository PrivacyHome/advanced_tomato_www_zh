<!-- Tomato GUI Copyright (C) 2006-2010 Jonathan Zarate http://www.polarcloud.com/tomato/
Filtering/Extensions on this QoS/Transfer Rates page Copyright (C) 2011
Augusto Bott http://code.google.com/p/tomato-sdhc-vlan/ For use with Tomato
Firmware only. No part of this file may be used without permission. -->
<title>
    连接传输速率
</title>
<content>
    <style type="text/css">
        #grid .co6 { text-align: right; } #grid .co7 { text-align: right; }
    </style>
    <script type="text/javascript" src="js/protocols.js">
    </script>
    <script type="text/javascript" src="js/interfaces.js">
    </script>
    <script type="text/javascript">
        //	<% nvram('at_update,tomatoanon_answer,qos_enable,lan_ipaddr,lan1_ipaddr,lan2_ipaddr,lan3_ipaddr,lan_netmask,lan1_netmask,lan2_netmask,lan3_netmask,t_hidelr'); %>
        var filterip = [];
        var filteripe = [];

        readDelay = fixInt('<% cgi_get("delay"); %>', 2, 30, 2);

        var queue = [];
        var xob = null;
        var cache = [];
        var lock = 0;

        function resolve() {
            if ((queue.length == 0) || (xob)) return;

            xob = new XmlHttp();
            xob.onCompleted = function(text, xml) {
                eval(text);
                for (var i = 0; i < resolve_data.length; ++i) {
                    var r = resolve_data[i];
                    if (r[1] == '') r[1] = r[0];
                    cache[r[0]] = r[1];
                    if (lock == 0) grid.setName(r[0], r[1]);
                }
                if (queue.length == 0) {
                    if ((lock == 0) && (resolveCB) && (grid.sortColumn == 4)) grid.resort();
                } else setTimeout(resolve, 500);
                xob = null;
            }
            xob.onError = function(ex) {
                xob = null;
            }

            xob.post('resolve.cgi', 'ip=' + queue.splice(0, 20).join(','));
        }

        var resolveCB = 0;
        var bcastCB = 0;
        var mcastCB = 0;

        function resolveChanged() {
            var b;

            b = E('_f_autoresolve').checked ? 1 : 0;
            if (b != resolveCB) {
                resolveCB = b;
                cookie.set('qos_ctr_resolve', b);
            }
            if (b) grid.resolveAll();
        }

        var thres = 0;

        function thresChanged() {
            var a, b;

            b = E('_f_excludebythreshold').checked ? fixInt('<% cgi_get("thres"); %>', 100, 10000000, 100) : 0;
            if (b != thres) {
                thres = b;
                cookie.set('qos_ctr_thres', b);
                ref.postData = 'exec=ctrate&arg0=' + readDelay + '&arg1=' + thres;
                if (!ref.running) ref.once = 1;
                E('loading').style.visibility = '';
                ref.start();
            }
        }

        var grid = new TomatoGrid();

        grid.dataToView = function(data) {
            var s, v = [];
            for (var col = 0; col < data.length; ++col) {
                switch (col) {
                case 5:
                case 6:
                    s = (data[col] / (readDelay * 1024)).toFixed(1);
                    break;
                default:
                    s = data[col];
                    break;
                }
                v.push('' + s);
            }
            return v;
        }

        grid.sortCompare = function(a, b) {
            var obj = TGO(a);
            var col = obj.sortColumn;
            var da = a.getRowData();
            var db = b.getRowData();
            var r;

            switch (col) {
            case 2:
            case 4:
            case 5:
            case 6:
                r = cmpInt(da[col], db[col]);
                break;
            case 1:
            case 3:
                var a = fixIP(da[col]);
                var b = fixIP(db[col]);
                if ((a != null) && (b != null)) {
                    r = aton(a) - aton(b);
                    break;
                }
            default:
                r = cmpText(da[col], db[col]);
                break;
            }
            return obj.sortAscending ? r: -r;
        }

        grid.onClick = function(cell) {
            var row = PR(cell);
            var ip = row.getRowData()[3];
            if (this.lastClicked != row) {
                this.lastClicked = row;
                if (ip.indexOf('<') == -1) {
                    queue.push(ip);
                    row.style.cursor = 'wait';
                    resolve();
                }
            } else {
                this.resolveAll();
            }
        }

        grid.resolveAll = function() {
            var i, ip, row, q, cols, j;

            q = [];
            cols = [1, 3];
            for (i = 1; i < this.tb.rows.length; ++i) {
                row = this.tb.rows[i];
                for (j = cols.length - 1; j >= 0; j--) {
                    ip = row.getRowData()[cols[j]];
                    if (ip.indexOf('<') == -1) {
                        if (!q[ip]) {
                            q[ip] = 1;
                            queue.push(ip);
                        }
                        row.style.cursor = 'wait';
                    }
                }
            }
            q = null;
            resolve();
        }

        grid.setName = function(ip, name) {
            var i, row, data, cols, j;

            cols = [1, 3];
            for (i = this.tb.rows.length - 1; i > 0; --i) {
                row = this.tb.rows[i];
                data = row.getRowData();
                for (j = cols.length - 1; j >= 0; j--) {
                    if (data[cols[j]] == ip) {
                        data[cols[j]] = name + ((ip.indexOf(':') != -1) ? '<br>': ' ') + '<small>(' + ip + ')</small>';
                        row.setRowData(data);
                        if (E('_f_shortcuts').checked) data[cols[j]] = data[cols[j]] + ' <small><a href="javascript:addExcludeList(\'' + ip + '\')" title="从列表中排除">[隐藏]</a></small>';
                        row.cells[cols[j]].innerHTML = data[cols[j]];
                        row.style.cursor = 'default';
                    }
                }
            }
        }

        grid.setup = function() {
            this.init('grid', 'sort');
            this.headerSet(['协议', '源', '源端口', '目标', '目标端口', '上传速率(KB/s)', '下载速率(KB/s)']);
        }

        var ref = new TomatoRefresh('/update.cgi', '', 0, 'qos_ctrate');

        var numconntotal = 0;
        var numconnshown = 0;

        ref.refresh = function(text) {
            var i, b, d, cols, j;

            ++lock;

            numconntotal = 0;
            numconnshown = 0;

            try {
                ctrate = [];
                eval(text);
            } catch(ex) {
                ctrate = [];
            }

            grid.lastClicked = null;
            grid.removeAllData();

            var c = [];
            var q = [];
            var cursor;
            var ip;

            var fskip;

            cols = [1, 2];

            for (i = 0; i < ctrate.length; ++i) {
                fskip = 0;
                numconntotal++;
                b = ctrate[i];

                if (E('_f_excludegw').checked) {
                    if ((b[1] == nvram.lan_ipaddr) || (b[2] == nvram.lan_ipaddr) || (b[1] == nvram.lan1_ipaddr) || (b[2] == nvram.lan1_ipaddr) || (b[1] == nvram.lan2_ipaddr) || (b[2] == nvram.lan2_ipaddr) || (b[1] == nvram.lan3_ipaddr) || (b[2] == nvram.lan3_ipaddr) || (b[1] == '127.0.0.1') || (b[2] == '127.0.0.1')) {
                        continue;
                    }
                }

                if (E('_f_excludebcast').checked) {
                    if ((b[2] == getBroadcastAddress(getNetworkAddress(nvram.lan_ipaddr, nvram.lan_netmask), nvram.lan_netmask)) || (b[2] == getBroadcastAddress(getNetworkAddress(nvram.lan1_ipaddr, nvram.lan1_netmask), nvram.lan1_netmask)) || (b[2] == getBroadcastAddress(getNetworkAddress(nvram.lan2_ipaddr, nvram.lan2_netmask), nvram.lan2_netmask)) || (b[2] == getBroadcastAddress(getNetworkAddress(nvram.lan3_ipaddr, nvram.lan3_netmask), nvram.lan3_netmask)) || (b[2] == '255.255.255.255') || (b[2] == '0.0.0.0')) {
                        continue;
                    }
                }

                if (E('_f_excludemcast').checked) {
                    var mmin = 3758096384; // aton('224.0.0.0') == 3758096384
                    var mmax = 4026531839; // aton('239.255.255.255') == 4026531839
                    if (((aton(b[1]) >= mmin) && (aton(b[1]) <= mmax)) || ((aton(b[2]) >= mmin) && (aton(b[2]) <= mmax))) {
                        continue;
                    }
                }

                if (filteripe.length > 0) {
                    fskip = 0;
                    for (x = 0; x < filteripe.length; ++x) {
                        if ((b[1] == filteripe[x]) || (b[2] == filteripe[x])) {
                            fskip = 1;
                            break;
                        }
                    }
                    if (fskip == 1) continue;
                }

                if (filterip.length > 0) {
                    fskip = 1;
                    for (x = 0; x < filterip.length; ++x) {
                        if ((b[1] == filterip[x]) || (b[2] == filterip[x])) {
                            fskip = 0;
                            break;
                        }
                    }
                    if (fskip == 1) continue;
                }

                for (j = cols.length - 1; j >= 0; j--) {
                    ip = b[cols[j]];
                    if (cache[ip] != null) {
                        c[ip] = cache[ip];
                        b[cols[j]] = cache[ip] + ((ip.indexOf(':') != -1) ? '<br>': ' ') + '<small>(' + ip + ')</small>';
                        cursor = 'default';
                    } else {
                        if (resolveCB) {
                            if (!q[ip]) {
                                q[ip] = 1;
                                queue.push(ip);
                            }
                            cursor = 'wait';
                        } else cursor = null;
                    }
                    if (E('_f_shortcuts').checked) {
                        if (cache[ip] == null) {
                            b[cols[j]] = b[cols[j]] + ' <small><a href="javascript:addToResolveQueue(\'' + ip + '\')" title="解析此地址的主机名">[解析]</a></small>';
                        }
                        b[cols[j]] = b[cols[j]] + ' <small><a href="javascript:addExcludeList(\'' + ip + '\')" title="过滤掉此IP">[隐藏]</a></small>';
                    }
                }

                numconnshown++;
                d = [protocols[b[0]] || b[0], b[1], b[3], b[2], b[4], b[5], b[6]];
                var row = grid.insertData( - 1, d);
                if (cursor) row.style.cursor = cursor;
            }
            cache = c;
            c = null;
            q = null;

            grid.resort();
            setTimeout(function() {
                E('loading').style.visibility = 'hidden';
            },
            100);

            --lock;

            if (resolveCB) resolve();

            if (numconnshown != numconntotal) E('numtotalconn').innerHTML = '<small><i>(显示 ' + numconnshown + ' 出站 ' + numconntotal + ' 连接数)</i></small>';
            else E('numtotalconn').innerHTML = '<small><i>(' + numconntotal + ' 连接数)</i></small>';
        }

        function addExcludeList(address) {
            if (E('_f_filter_ipe').value.length < 6) {
                E('_f_filter_ipe').value = address;
            } else {
                if (E('_f_filter_ipe').value.indexOf(address) < 0) {
                    E('_f_filter_ipe').value = E('_f_filter_ipe').value + ',' + address;
                }
            }
            dofilter();
        }

        function addToResolveQueue(ip) {
            queue.push(ip);
            resolve();
        }

        function init() {
            var c;

            if ((c = cookie.get('qos_filterip')) != null) {
                cookie.set('qos_filterip', '', 0);
                if (c.length > 6) {
                    E('_f_filter_ip').value = c;
                    filterip = c.split(',');
                }
            }

            if (((c = cookie.get('qos_ctr_resolve')) != null) && (c == '1')) {
                E('_f_autoresolve').checked = resolveCB = 1;
            }

            if (((c = cookie.get('qos_ctr_bcast')) != null) && (c == '1')) {
                E('_f_excludebcast').checked = bcastCB = 1;
            }

            if (((c = cookie.get('qos_ctr_mcast')) != null) && (c == '1')) {
                E('_f_excludemcast').checked = mcastCB = 1;
            }

            if (((c = cookie.get('qos_ctr_filters_vis')) != null) && (c == '1')) {
                toggleVisibility("filters");
            }

            if ((thres = cookie.get('qos_ctr_thres')) == null || isNaN(thres *= 1)) {
                thres = 0;
            }

            E('_f_shortcuts').checked = (((c = cookie.get('qos_ctr_shortcuts')) != null) && (c == '1'));

            E('_f_excludebythreshold').checked = (thres != 0);
            grid.setup();
            ref.postData = 'exec=ctrate&arg0=' + readDelay + '&arg1=' + thres;
            ref.initPage(250);

            if (!ref.running) ref.once = 1;
            ref.start();
        }

        function dofilter() {
            if (E('_f_filter_ip').value.length > 6) {
                filterip = E('_f_filter_ip').value.split(',');
            } else {
                filterip = [];
            }

            if (E('_f_filter_ipe').value.length > 6) {
                filteripe = E('_f_filter_ipe').value.split(',');
            } else {
                filteripe = [];
            }

            if (!ref.running) ref.start();
        }

        function toggleVisibility(whichone) {
            if (E('sesdiv' + whichone).style.display == '') {
                E('sesdiv' + whichone).style.display = 'none';
                E('sesdiv' + whichone + 'showhide').innerHTML = '<i class="icon-chevron-up"></i>';
                cookie.set('qos_ctr_' + whichone + '_vis', 0);
            } else {
                E('sesdiv' + whichone).style.display = '';
                E('sesdiv' + whichone + 'showhide').innerHTML = '<i class="icon-chevron-down"></i>';
                cookie.set('qos_ctr_' + whichone + '_vis', 1);
            }
        }

        function verifyFields(focused, quiet) {
            var b;

            b = E('_f_excludebcast').checked ? 1 : 0;
            if (b != bcastCB) {
                bcastCB = b;
                cookie.set('qos_ctr_bcast', b);
            }

            b = E('_f_excludemcast').checked ? 1 : 0;
            if (b != mcastCB) {
                mcastCB = b;
                cookie.set('qos_ctr_mcast', b);
            }

            cookie.set('qos_ctr_shortcuts', (E('_f_shortcuts').checked ? '1': '0'), 1);

            thresChanged();
            resolveChanged();
            dofilter();
            return 1;
        }
    </script>
    <script type="text/javascript">
        if (nvram.qos_enable != '1') {
            $('.container .ajaxwrap').prepend('<div class="alert alert-info"><b>QoS 已禁用.</b>&nbsp; <a class="ajaxload" href="#qos-settings.asp">启用 &raquo;</a> <a class="close"><i class="icon-cancel"></i></a></div>');
        }
    </script>
    <div class="box" id="qos-transfer-rates">
        <div class="heading">
            QOS 传输速率
            <span id="numtotalconn">
            </span>
        </div>
        <div class="content">
            <h4>
                筛选程序
                <a href="javascript:toggleVisibility('filters');">
                    <span id="sesdivfiltersshowhide">
                        <i class="icon-chevron-up">
                        </i>
                    </span>
                </a>
            </h4>
            <div class="section" id="sesdivfilters" style="display:none">
            </div>
            <script type="text/javascript">
                var c;
                c = [];
                c.push({
                    title: '只显示这些IP',
                    name: 'f_filter_ip',
                    size: 50,
                    maxlen: 255,
                    type: 'text',
                    suffix: ' <small>(逗号分隔列表)</small>'
                });
                c.push({
                    title: '排除这些IP',
                    name: 'f_filter_ipe',
                    size: 50,
                    maxlen: 255,
                    type: 'text',
                    suffix: ' <small>(逗号分隔列表)</small>'
                });
                c.push({
                    title: '排除网关通信',
                    name: 'f_excludegw',
                    type: 'checkbox',
                    value: ((nvram.t_hidelr) == '1' ? 1 : 0)
                });
                c.push({
                    title: '排除IPv4广播',
                    name: 'f_excludebcast',
                    type: 'checkbox'
                });
                c.push({
                    title: '排除IPv4组播',
                    name: 'f_excludemcast',
                    type: 'checkbox'
                });
                c.push({
                    title: '忽略非活动连接',
                    name: 'f_excludebythreshold',
                    type: 'checkbox'
                });
                c.push({
                    title: '自动解析地址',
                    name: 'f_autoresolve',
                    type: 'checkbox'
                });
                c.push({
                    title: '显示快捷键',
                    name: 'f_shortcuts',
                    type: 'checkbox'
                });
                $('#sesdivfilters').forms(c);
            </script>
            <br />
            <table id="grid" class="line-table">
            </table>
            <div id="loading">
                <br>
                <b>
                    加载中...
                </b>
                <div class="spinner">
                </div>
            </div>
        </div>
    </div>
    <script type="text/javascript">
        $('#qos-transfer-rates').after(genStdRefresh(1, 1, 'ref.toggle()'));
        init();
    </script>
</content>