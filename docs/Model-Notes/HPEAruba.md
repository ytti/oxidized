# HPE Aruba Networking devices
HPE Aruba offers various networking devices with different operating systems.

## HPE Aruba Networking Instant Mode (Aruba Instant)
[Aruba Instant](https://www.arubanetworks.com/techdocs/ArubaDocPortal/content/cons-instant-home.htm)
runs on IAPs (Instant Access points).

The Oxidized model is [ArubaInstant](/lib/oxidized/model/arubainstant.rb).
When run on the virtual WLAN controller, it will also collect the list of the
WLAN-AP linked to the controller.

The aosw model for AOS 8 used to be used for Aruba Instant, but it does not work
as well and may stop working in the future.

## HPE Aruba Networking Wireless Operating System 8 (AOS 8)
[AOS 8](https://www.arubanetworks.com/techdocs/ArubaDocPortal/content/cons-aos-home.htm)
runs on WLAN controllers (mobility controllers) and controller-managed access
points.

The Oxidized model is [aosw](/lib/oxidized/model/aosw.rb).

## HPE Aruba Networking CX Switch Operating System (AOS-CX)
[AOS-CX](https://www.arubanetworks.com/techdocs/AOS-CX/help_portal/Content/home.htm)
is the operating system for the newer CX-Series.

The Oxidized model is [aoscx](/lib/oxidized/model/aoscx.rb).

## Older Models
Older Devices like ProCurve or 3Com/Comware are listed under the Vendor "HP" in
the [Supported OS Types](docs/Supported-OS-Types.md) list.

