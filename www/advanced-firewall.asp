<!--
Tomato GUI
Copyright (C) 2006-2010 Jonathan Zarate
http://www.polarcloud.com/tomato/

Tomato VLAN GUI
Copyright (C) 2011 Augusto Bott
http://code.google.com/p/tomato-sdhc-vlan/

For use with Tomato Firmware only.
No part of this file may be used without permission.
--><title>防火墙</title>
<content>
	<script type="text/javascript">
		//	<% nvram("block_wan,block_wan_limit,block_wan_limit_icmp,block_wan_limit_tr,nf_loopback,ne_syncookies,DSCP_fix_enable,ipv6_ipsec,multicast_pass,multicast_lan,multicast_lan1,multicast_lan2,multicast_lan3,lan_ifname,lan1_ifname,lan2_ifname,lan3_ifname,udpxy_enable,udpxy_stats,udpxy_clients,udpxy_port,ne_snat"); %>

		function verifyFields( focused, quiet ) {
			/* ICMP */
			E( '_f_icmp_limit' ).disabled = !E( '_f_icmp' ).checked;
			E( '_f_icmp_limit_icmp' ).disabled = (!E( '_f_icmp' ).checked || !E( '_f_icmp_limit' ).checked);
			E( '_f_icmp_limit_traceroute' ).disabled = (!E( '_f_icmp' ).checked || !E( '_f_icmp_limit' ).checked);

			/* VLAN-BEGIN */
			var enable_mcast = E( '_f_multicast' ).checked;
			E( '_f_multicast_lan' ).disabled = ((!enable_mcast) || (nvram.lan_ifname.length < 1));
			E( '_f_multicast_lan1' ).disabled = ((!enable_mcast) || (nvram.lan1_ifname.length < 1));
			E( '_f_multicast_lan2' ).disabled = ((!enable_mcast) || (nvram.lan2_ifname.length < 1));
			E( '_f_multicast_lan3' ).disabled = ((!enable_mcast) || (nvram.lan3_ifname.length < 1));
			if ( nvram.lan_ifname.length < 1 )
				E( '_f_multicast_lan' ).checked = false;
			if ( nvram.lan1_ifname.length < 1 )
				E( '_f_multicast_lan1' ).checked = false;
			if ( nvram.lan2_ifname.length < 1 )
				E( '_f_multicast_lan2' ).checked = false;
			if ( nvram.lan3_ifname.length < 1 )
				E( '_f_multicast_lan3' ).checked = false;
			if ( (enable_mcast) && (!E( '_f_multicast_lan' ).checked) && (!E( '_f_multicast_lan1' ).checked) && (!E( '_f_multicast_lan2' ).checked) && (!E( '_f_multicast_lan3' ).checked) ) {
				ferror.set( '_f_multicast', '开启IGMPproxy必须选择一个LAN口', quiet );
				return 0;
			} else {
				ferror.clear( '_f_multicast' );
			}
			/* VLAN-END */
			E( '_f_udpxy_stats' ).disabled = !E( '_f_udpxy_enable' ).checked;
			E( '_f_udpxy_clients' ).disabled = !E( '_f_udpxy_enable' ).checked;
			E( '_f_udpxy_port' ).disabled = !E( '_f_udpxy_enable' ).checked;
			return 1;
		}

		function save() {

			var fom;

			if ( !verifyFields( null, 0 ) ) return;

			fom = E( '_fom' );
			fom.block_wan.value = E( '_f_icmp' ).checked ? 0 : 1;
			fom.block_wan_limit.value = E( '_f_icmp_limit' ).checked ? 1 : 0;
			fom.block_wan_limit_icmp.value = E( '_f_icmp_limit_icmp' ).value;
			fom.block_wan_limit_tr.value = E( '_f_icmp_limit_traceroute' ).value;

			fom.ne_syncookies.value = E( '_f_syncookies' ).checked ? 1 : 0;
			fom.DSCP_fix_enable.value = E( '_f_DSCP_fix_enable' ).checked ? 1 : 0;
			fom.ipv6_ipsec.value = E( '_f_ipv6_ipsec' ).checked ? 1 : 0;
			fom.multicast_pass.value = E( '_f_multicast' ).checked ? 1 : 0;
			fom.multicast_lan.value = E( '_f_multicast_lan' ).checked ? 1 : 0;
			fom.multicast_lan1.value = E( '_f_multicast_lan1' ).checked ? 1 : 0;
			fom.multicast_lan2.value = E( '_f_multicast_lan2' ).checked ? 1 : 0;
			fom.multicast_lan3.value = E( '_f_multicast_lan3' ).checked ? 1 : 0;
			fom.udpxy_enable.value = E( '_f_udpxy_enable' ).checked ? 1 : 0;
			fom.udpxy_stats.value = E( '_f_udpxy_stats' ).checked ? 1 : 0;
			fom.udpxy_clients.value = E( '_f_udpxy_clients' ).value;
			fom.udpxy_port.value = E( '_f_udpxy_port' ).value;
			form.submit( fom, 1 );

		}
	</script>

	<form id="_fom" method="post" action="tomato.cgi">
		<input type="hidden" name="_nextpage" value="/#advanced-firewall.asp">
		<input type="hidden" name="_service" value="firewall-restart">

		<input type="hidden" name="block_wan">
		<input type="hidden" name="block_wan_limit">
		<input type="hidden" name="block_wan_limit_icmp">
		<input type="hidden" name="block_wan_limit_tr">
		<input type="hidden" name="ne_syncookies">
		<input type="hidden" name="DSCP_fix_enable">
		<input type="hidden" name="ipv6_ipsec">
		<input type="hidden" name="multicast_pass">
		<input type="hidden" name="multicast_lan">
		<input type="hidden" name="multicast_lan1">
		<input type="hidden" name="multicast_lan2">
		<input type="hidden" name="multicast_lan3">
		<input type="hidden" name="udpxy_enable">
		<input type="hidden" name="udpxy_stats">
		<input type="hidden" name="udpxy_clients">
		<input type="hidden" name="udpxy_port">

		<div class="box" data-box="firewal-set">
			<div class="heading">防火墙设置</div>
			<div class="section firewall content"></div>
			<script type="text/javascript">
				$( '.section.firewall' ).forms(
					[
					{ title: '响应ICMP ping', name: 'f_icmp', type: 'checkbox', value: nvram.block_wan == '0' },
					{ title: '每秒限制', name: 'f_icmp_limit', type: 'checkbox', value: nvram.block_wan_limit != '0' },
					{ title: 'ICMP', indent: 2, name: 'f_icmp_limit_icmp', type: 'text', maxlen: 3, size: 3, suffix: ' <small> 每秒请求次数</small>', value: fixInt( nvram.block_wan_limit_icmp || 1, 1, 300, 5 ) },
					{ title: '追踪路由', indent: 2, name: 'f_icmp_limit_traceroute', type: 'text', maxlen: 3, size: 3, suffix: ' <small> 每秒请求次数</small>', value: fixInt( nvram.block_wan_limit_tr || 5, 1, 300, 5 ) },
					null,
					{ title: '启用SYN Cookie', name: 'f_syncookies', type: 'checkbox', value: nvram.ne_syncookies != '0' },
					{ title: '启用DSCP修复', name: 'f_DSCP_fix_enable', type: 'checkbox', value: nvram.DSCP_fix_enable != '0', suffix: ' <small>修复功能不正常DSCP</small>' },
					{ title: 'IPv6 IPSec 通道', name: 'f_ipv6_ipsec', type: 'checkbox', value: nvram.ipv6_ipsec != '0' }
					]
					);
			</script>
		</div>

		<div class="box" data-box="firewall-nat">
			<div class="heading">NAT</div>
			<div class="section natfirewall content"></div>
			<script type="text/javascript">
				$( '.section.natfirewall' ).forms(
					[
					{ title: 'NAT回环', name: 'nf_loopback', type: 'select', options: [ [ 0, '全部' ], [ 1, '仅转发' ], [ 2, '禁用' ] ], value: fixInt( nvram.nf_loopback, 0, 2, 1 ) },
					{ title: 'NAT目标', name: 'ne_snat', type: 'select', options: [ [ 0, '伪装' ], [ 1, '源地址转换' ] ], value: nvram.ne_snat }
					] );
			</script>
		</div>

		<div class="box" data-box="firewall-multicast">
			<div class="heading">多播协议</div>
			<div class="section multicast content"></div>
			<script type="text/javascript">
				$( '.section.multicast' ).forms(
						[
							{ title: '启用 IGMPproxy', name: 'f_multicast', type: 'checkbox', value: nvram.multicast_pass == '1' },
							/* VLAN-BEGIN */
							{ title: 'LAN', indent: 2, name: 'f_multicast_lan', type: 'checkbox', value: (nvram.multicast_lan == '1') },
							{ title: 'LAN1', indent: 2, name: 'f_multicast_lan1', type: 'checkbox', value: (nvram.multicast_lan1 == '1') },
							{ title: 'LAN2', indent: 2, name: 'f_multicast_lan2', type: 'checkbox', value: (nvram.multicast_lan2 == '1') },
							{ title: 'LAN3', indent: 2, name: 'f_multicast_lan3', type: 'checkbox', value: (nvram.multicast_lan3 == '1') },
							/* VLAN-END */
							{ title: '启用 Udpxy', name: 'f_udpxy_enable', type: 'checkbox', value: (nvram.udpxy_enable == '1') },
							{ title: '启用客户端统计', indent: 2, name: 'f_udpxy_stats', type: 'checkbox', value: (nvram.udpxy_stats == '1') },
							{ title: '最大客户端', indent: 2, name: 'f_udpxy_clients', type: 'text', maxlen: 4, size: 6, value: fixInt( nvram.udpxy_clients || 3, 1, 5000, 3 ) },
							{ title: 'Udpxy 端口', indent: 2, name: 'f_udpxy_port', type: 'text', maxlen: 5, size: 7, value: fixPort( nvram.udpxy_port, 4022 ) }
						] );
			</script>
		</div>

		<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">保存 <i class="icon-check"></i></button>
		<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">取消 <i class="icon-cancel"></i></button>
		<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>

	</form>

	<script type="text/javascript">verifyFields( null, 1 );</script>
</content>