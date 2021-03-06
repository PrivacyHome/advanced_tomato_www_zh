<!--
Tomato GUI
Copyright (C) 2006-2010 Jonathan Zarate
http://www.polarcloud.com/tomato/

For use with Tomato Firmware only.
No part of this file may be used without permission.
--><title>管理设置</title>
<content>
	<script type="text/javascript" src="js/interfaces.js"></script>
	<script type="text/javascript">
		// <% nvram("at_nav,at_nav_action,at_nav_state,http_enable,https_enable,http_lanport,https_lanport,remote_management,remote_mgt_https,web_wl_filter,web_css,web_dir,ttb_css,sshd_eas,sshd_pass,sshd_remote,telnetd_eas,http_wanport,sshd_authkeys,sshd_port,sshd_rport,sshd_forwarding,telnetd_port,rmgt_sip,https_crt_cn,https_crt_save,lan_ipaddr,ne_shlimit,sshd_motd,http_username,http_root"); %>
		changed = 0;
		tdup = parseInt("<% psup('telnetd'); %>");
		sdup = parseInt("<% psup('dropbear'); %>");
		shlimit = nvram.ne_shlimit.split(",");
		if (shlimit.length != 3) shlimit = [0,3,60];
		var xmenus = [["状态", "status"], ["带宽监控", "bwm"], ["IP流量监控", "ipt"], ["工具", "tools"], ["基本设置", "basic"],
			["高级设置", "advanced"], ["端口转发", "forward"], ["Qos服务", "qos"],
			/* USB-BEGIN */
			['USB和NAS', 'nas'],
			/* USB-END */
			/* VPN-BEGIN */
			['VPN服务器', 'vpn'],
			/* VPN-END */
			['系统管理', 'admin']];
		function toggle(service, isup)
		{
			if (changed > 0) {
				if (!confirm("未保存的更改将丢失。继续吗?")) return;
			}
			E("_" + service + "_button").disabled = true;
			$('#_' + service + "_button").after(' <div class="spinner"></div>');
			form.submitHidden("service.cgi", {
				_redirect: "/#admin-access.asp",
				_sleep: ((service == "sshd") && (!isup)) ? "7" : "3",
				_service: service + (isup ? "-stop" : "-start")
			});
		}
		function verifyFields(focused, quiet)
		{

			var ok = 1;
			var a, b, c;
			var i;
			var o = (E("_web_css").value == "online");
			var p = nvram.ttb_css;

			elem.display(PR("_ttb_css"), o);

			try {
				a = E("_web_css").value;
				if (a == "online") {
					E("guicss").href = "ext/" + p + ".css";
					nvram.web_css = a;
				} else {
					if (a != nvram.web_css) {
						E("guicss").href = a + ".css";
						nvram.web_css = a;
					}
				}
			}
			catch (ex) {
			}

			a = E("_f_http_local");
			b = E("_f_http_remote").value;
			if ((a.value != 3) && (b != 0) && (a.value != b)) {
				ferror.set(a, "开启远程访问必须开启本地HTTP/HTTPS。", quiet || !ok);
				ok = 0;
			}
			else {
				ferror.clear(a);
			}

			elem.display(PR("_http_lanport"), (a.value == 1) || (a.value == 3));
			c = (a.value == 2) || (a.value == 3);
			elem.display(PR("_https_lanport"), "row_sslcert", PR("_https_crt_cn"), PR("_f_https_crt_save"), PR("_f_https_crt_gen"), c);

			if (c) {
				a = E("_https_crt_cn");
				a.value = a.value.replace(/(,+|\s+)/g, " ").trim();
				if (a.value != nvram.https_crt_cn) E("_f_https_crt_gen").checked = 1;
			}

			if ((!v_port("_http_lanport", quiet || !ok)) || (!v_port("_https_lanport", quiet || !ok))) ok = 0;
			b = b != 0;
			a = E("_http_wanport");
			elem.display(PR(a), b);
			if ((b) && (!v_port(a, quiet || !ok))) ok = 0;
			if (!v_port("_telnetd_port", quiet || !ok)) ok = 0;
			a = E("_f_sshd_remote").checked;
			b = E("_sshd_rport");
			elem.display(PR(b), a);
			if ((a) && (!v_port(b, quiet || !ok))) ok = 0;
			a = E("_sshd_authkeys");
			if (!v_length(a, quiet || !ok, 0, 4096)) {
				ok = 0;
			}
			else if (a.value != "") {
				if (a.value.search(/^\s*ssh-(dss|rsa)/) == -1) {
					ferror.set(a, "无效的SSH密钥。", quiet || !ok);
					ok = 0;
				}
			}
			a = E("_f_rmgt_sip");
			if ((a.value.length) && (!_v_iptaddr(a, quiet || !ok, 15, 1, 1))) return 0;
			ferror.clear(a);
			if (!v_range("_f_limit_hit", quiet || !ok, 1, 100)) return 0;
			if (!v_range("_f_limit_sec", quiet || !ok, 3, 3600)) return 0;
			a = E("_set_password_1");
			b = E("_set_password_2");
			a.value = a.value.trim();
			b.value = b.value.trim();
			if (a.value != b.value) {
				ferror.set(b, "两个密码必须匹配。", quiet || !ok);
				ok = 0;
			}
			else if (a.value == "") {
				ferror.set(a, "密码不能为空。", quiet || !ok);
				ok = 0;
			}
			else {
				ferror.clear(a);
				ferror.clear(b);
			}
			changed |= ok;
			return ok;
		}

		function save()
		{
			var a, b, fom;
			if (!verifyFields(null, false)) return;
			fom = E("_fom");
			a = E("_f_http_local").value * 1;
			if (a == 0) {
				if (!confirm("警告: Web管理即将被禁用。 如果您决定稍后重新启用Web Admin，则必须通过Telnet，SSH或通过执行硬件重置手动完成。 您确定要执行此操作?")) return;
				fom._nextpage.value = "about:blank";
			}
			fom.http_enable.value = (a & 1) ? 1 : 0;
			fom.https_enable.value = (a & 2) ? 1 : 0;
			nvram.lan_ipaddr = location.hostname;
			if ((a != 0) && (location.hostname == nvram.lan_ipaddr)) {
				if (location.protocol == "https:") {
					b = "s";
					if ((a & 2) == 0) b = "";
				}
				else {
					b = "";
					if ((a & 1) == 0) b = "s";
				}
				a = "http" + b + "://" + location.hostname;
				if (b == "s") {
					if (fom.https_lanport.value != 443) a += ":" + fom.https_lanport.value;
				}
				else {
					if (fom.http_lanport.value != 80) a += ":" + fom.http_lanport.value;
				}
				fom._nextpage.value = a + "/#admin-access.asp";
			}
			a = E("_f_http_remote").value;
			fom.remote_management.value = (a != 0) ? 1 : 0;
			fom.remote_mgt_https.value = (a == 2) ? 1 : 0;
			/*
			if ((a != 0) && (location.hostname != nvram.lan_ipaddr)) {
			if (location.protocol == "https:") {
			if (a != 2) fom._nextpage.value = "http://" + location.hostname + ":" + fom.http_wanport.value + "/admin-access.asp";
			}
			else {
			if (a == 2) fom._nextpage.value = "https://" + location.hostname + ":" + fom.http_wanport.value + "/admin-access.asp";
			}
			}
			*/
			fom.https_crt_gen.value = E("_f_https_crt_gen").checked ? 1 : 0;
			fom.https_crt_save.value = E("_f_https_crt_save").checked ? 1 : 0;
			fom.http_root.value = E('_f_http_root').checked ? 1 : 0;
			fom.web_wl_filter.value = E("_f_http_wireless").checked ? 0 : 1;
			fom.telnetd_eas.value = E("_f_telnetd_eas").checked ? 1 : 0;
			fom.sshd_eas.value = E("_f_sshd_eas").checked ? 1 : 0;
			fom.sshd_pass.value = E("_f_sshd_pass").checked ? 1 : 0;
			fom.sshd_remote.value = E("_f_sshd_remote").checked ? 1 : 0;
			fom.sshd_motd.value = E('_f_sshd_motd').checked ? 1 : 0;
			fom.sshd_forwarding.value = E("_f_sshd_forwarding").checked ? 1 : 0;
			fom.rmgt_sip.value = fom.f_rmgt_sip.value.split(/\s*,\s*/).join(",");
			fom.ne_shlimit.value = ((E("_f_limit_ssh").checked ? 1 : 0) | (E("_f_limit_telnet").checked ? 2 : 0)) +
			"," + E("_f_limit_hit").value + "," + E("_f_limit_sec").value;

			a = [];

			form.submit(fom, 0);
		}
		function init() {
			changed = 0;
		}
	</script>

	<form id="_fom" method="post" action="tomato.cgi">

		<input type="hidden" name="_nextpage" value="/#admin-access.asp">
		<input type="hidden" name="_nextwait" value="10">
		<input type="hidden" name="_service" value="admin-restart">

		<input type="hidden" name="http_enable">
		<input type="hidden" name="https_enable">
		<input type="hidden" name="https_crt_save">
		<input type="hidden" name="https_crt_gen">
		<input type="hidden" name="http_root">
		<input type="hidden" name="remote_management">
		<input type="hidden" name="remote_mgt_https">
		<input type="hidden" name="web_wl_filter">
		<input type="hidden" name="telnetd_eas">
		<input type="hidden" name="sshd_eas">
		<input type="hidden" name="sshd_pass">
		<input type="hidden" name="sshd_remote">
		<input type="hidden" name="sshd_motd">
		<input type="hidden" name="ne_shlimit">
		<input type="hidden" name="rmgt_sip">
		<input type="hidden" name="sshd_forwarding">
		<input type="hidden" name="web_mx">

		<div class="box" data-box="admin-access">
			<div class="heading">管理员访问设置</div>
			<div class="content" id="section-gui">

				<script type="text/javascript">
					var m = [
						{ title: '本地访问', name: 'f_http_local', type: 'select', options: [[0,'禁用'],[1,'HTTP'],[2,'HTTPS'],[3,'HTTP &amp; HTTPS']],
							value: ((nvram.https_enable != 0) ? 2 : 0) | ((nvram.http_enable != 0) ? 1 : 0) },
						{ title: 'HTTP端口', indent: 2, name: 'http_lanport', type: 'text', maxlen: 5, size: 7, value: fixPort(nvram.http_lanport, 80) },
						{ title: 'HTTPS端口', indent: 2, name: 'https_lanport', type: 'text', maxlen: 5, size: 7, value: fixPort(nvram.https_lanport, 443) },
						{ title: '<h5>SSL证书</h5>', rid: 'row_sslcert' },
						{ title: '通用名称(CN)', indent: 2, name: 'https_crt_cn', help: 'optional; space separated', type: 'text',
							maxlen: 64, size: 64, value: nvram.https_crt_cn },
						{ title: '重新生成', indent: 2, name: 'f_https_crt_gen', type: 'checkbox', value: 0 },
						{ title: '保存至NVRAM', indent: 2, name: 'f_https_crt_save', type: 'checkbox', value: nvram.https_crt_save == 1 },
						{ title: '远程访问', name: 'f_http_remote', type: 'select', options: [[0,'禁用'],[1,'HTTP'],[2,'HTTPS']],
							value:  (nvram.remote_management == 1) ? ((nvram.remote_mgt_https == 1) ? 2 : 1) : 0 },
						{ title: '端口', indent: 2, name: 'http_wanport', type: 'text', maxlen: 5, size: 7, value:  fixPort(nvram.http_wanport, 8080) },
						{ title: '允许无线访问', name: 'f_http_wireless', type: 'checkbox', value:  nvram.web_wl_filter == 0 },
						{ title: '<h5>用户界面设置</h5>' },
						{ title: '界面主题', name: 'web_css', type: 'select', help: 'AdvancedTomato很少建立皮肤,通过这种方式我们可以节省路由器空间并添加更重要的功能。',
							options: [['tomato','默认'],
							['css/schemes/green-scheme','绿色风格'],
							['css/schemes/red-scheme','红色风格'],
							['css/schemes/torquoise-scheme','绿松石风格'],
							['ext/custom','自定义 (ext/custom.css)'],
							['online', '在线获取ATTD主题']], value: nvram.web_css },
						{ title    : '导航显示', name: 'at_nav_action', type: 'select', help: '此选项允许您更改使用导航菜单（左侧）的方法。',
							options: [ [ 'click', '鼠标点击' ], ['hover', '鼠标焦点'] ], value: nvram.at_nav_action },
						{ title: '默认导航状态', name: 'at_nav_state', type: 'select', help: '您可以随时点击图标直接切换导航样式，但这样做不会更改默认状态。',
							options: [['default', '默认'], ['collapsed', '折叠']], value: nvram.at_nav_state },
						{ title: 'ATTD ID#', indent: 2, name: 'ttb_css', type: 'text', maxlen: 25, size: 30, value: nvram.ttb_css, suffix: 'Theme ID# from <a href="http://advancedtomato.com/themes/" target="_blank"><u><i>ATTD themes gallery</i></u></a>' },
						{ title: '界面文件目录', name: 'web_dir', type: 'select', help: '只有专家！这将改变从Tomato网站处理程序读取接口文件的目录。如果您有特定目录的另一个接口时，才应更改此。',
							options: [['default','默认: /www'], ['jffs', '自定义: /jffs/www (专家！)'], ['opt', '自定义: /opt/www (专家！)'], ['tmp', '自定义: /tmp/www (专家！)']], value: nvram.web_dir, suffix: ' <small>更改此设置之前，请确保您的决定！</small>' },
						{ title: '导航菜单', help: "此选项可以扩展导航菜单的JavaScript对象（见Tomato.js源代码，获取更多信息）。这是高级选项，以便照顾！只有JSON格式接受！",
							name: 'at_nav', type: 'textarea', style: 'width: 100%; height: 100px;', value: nvram.at_nav }
					];

					// createFieldTable('', m, '#section-gui', 'fields-table');
					$('#section-gui').forms(m);
				</script>
			</div>
		</div>

		<div class="box" data-box="admin-weblogin">
			<div class="heading">授权设置</div>
			<div class="content" id="section-weblogin">
				<script type="text/javascript">
					$('#section-weblogin').forms([
						{ title: '用户名', name: 'http_username', type: 'text', value: nvram.http_username, suffix: '&nbsp;<small>(空字段表示“admin”)</small>' },
						{ title: '允许Web登录为“root”', name: 'f_http_root', type: 'checkbox', value: nvram.http_root == 1 },
						{ title: '密码', name: 'set_password_1', type: 'password', value: '**********' },
						{ title: '重复输入密码', indent: 2, name: 'set_password_2', type: 'password', value: '**********' }
					]);
				</script>
			</div>
		</div>


		<div class="box" id="section-ssh" data-box="access-ssh">
			<div class="heading">SSH 服务<span class="ssh-status"></span></div>
			<div class="content">
				<script type="text/javascript">
					$('#section-ssh .content').forms([
						{ title: '开启启动', name: 'f_sshd_eas', type: 'checkbox', value: nvram.sshd_eas == 1 },
						{ title: '扩展 MOTD', name: 'f_sshd_motd', type: 'checkbox', value: nvram.sshd_motd == 1 },
						{ title: '远程访问', name: 'f_sshd_remote', type: 'checkbox', value: nvram.sshd_remote == 1 },
						{ title: '远程端口', indent: 2, name: 'sshd_rport', type: 'text', maxlen: 5, size: 7, value: nvram.sshd_rport },
						{ title: '远程转发', name: 'f_sshd_forwarding', type: 'checkbox', value: nvram.sshd_forwarding == 1 },
						{ title: '端口', name: 'sshd_port', type: 'text', maxlen: 5, size: 7, value: nvram.sshd_port },
						{ title: '使用密码登录', name: 'f_sshd_pass', type: 'checkbox', value: nvram.sshd_pass == 1 },
						{ title: '使用认证密钥', name: 'sshd_authkeys', style: 'width: 100%; height: 100px;', type: 'textarea', value: nvram.sshd_authkeys }
					]);
					$('#section-ssh .heading').append('<a href="#" data-toggle="tooltip" class="pull-right" title="' + (sdup ? '停止' : '启动') + ' SSH 服务" onclick="toggle(\'sshd\', sdup)" id="_sshd_button">'
						+ (sdup ? '<i class="icon-stop"></i>' : '<i class="icon-play"></i>') + '</a>');
					$('.ssh-status').html((sdup ? '<small style="color: green;">(运行中)</small>' : '<small style="color: red;">(未运行)</small>'));
				</script>
			</div>
		</div>

		<div class="box" id="section-telnet" data-box="access-telnet">
			<div class="heading">Telnet 服务<span class="telnet-status"></span></div>
			<div class="content">
				<script type="text/javascript">
					$('#section-telnet .content').forms([
						{ title: '开机启动', name: 'f_telnetd_eas', type: 'checkbox', value: nvram.telnetd_eas == 1 },
						{ title: '端口', name: 'telnetd_port', type: 'text', maxlen: 5, size: 7, value: nvram.telnetd_port }
					]);
					$('#section-telnet .heading').append('<a href="#" data-toggle="tooltip" class="pull-right" title="' + (tdup ? '停止' : '启动') + ' Telnet 服务" onclick="toggle(\'telnetd\', tdup)" id="_telnetd_button">'
						+ (tdup ? '<i class="icon-stop"></i>' : '<i class="icon-play"></i>') + '</a>');
					$('.telnet-status').html((tdup ? '<small style="color: green;">(运行中)</small>' : '<small style="color: red;">(未运行)</small>'));
				</script>
			</div>
		</div>

		<div class="box" id="section-restrict" data-box="access-restrict">
			<div class="heading">管理限制</div>
			<div class="content">
				<script type="text/javascript">
					$('#section-restrict .content').forms([
						{ title: '允许的远程IP地址', name: 'f_rmgt_sip', type: 'text', maxlen: 512, size: 64, value: nvram.rmgt_sip,
							suffix: '<small>(可选; 例如: "1.1.1.1", "1.1.1.0/24", "1.1.1.1 - 2.2.2.2" 或 "me.example.com")</small>' },
						{ title: '最大尝试次数', multi: [
							{ suffix: ' SSH &nbsp; / &nbsp;', name: 'f_limit_ssh', type: 'checkbox', value: (shlimit[0] & 1) != 0 },
							{ suffix: ' Telnet &nbsp;', name: 'f_limit_telnet', type: 'checkbox', value: (shlimit[0] & 2) != 0 }
						] },
						{ title: '', indent: 2, multi: [
							{ name: 'f_limit_hit', type: 'text', maxlen: 4, size: 6, suffix: '每 ', value: shlimit[1] },
							{ name: 'f_limit_sec', type: 'text', maxlen: 4, size: 6, suffix: '秒', value: shlimit[2] }
						] }
					]);
				</script>
			</div>
		</div>

		<button type="button" value="Save" id="save-button" onclick="save();" class="btn btn-primary">保存 <i class="icon-check"></i></button>
		<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">取消 <i class="icon-cancel"></i></button>
		<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>
	</form>

	<script type="text/javascript">init(); verifyFields(null, 1);</script>
</content>
