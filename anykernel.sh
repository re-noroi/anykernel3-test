# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=FakeDreamer Kernel by Re-Noroi
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=apollo
device.name2=apollon
device.name3=
device.name4=
device.name5=
supported.versions=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 750 750 $ramdisk/*;

# kernel naming scene
ui_print " ";

# Check if we are using sideload with 'update.zip' or 'package.zip' and if sideload.txt exists
if { [ "$(basename "$ZIPFILE")" = "update.zip" ] || [ "$(basename "$ZIPFILE")" = "package.zip" ]; }; then
  ui_print "Detected sideload, using manual configuration..."
  ui_print " ";

  # Detect .dreamless file and analyze the filename
  DREAMLESS_FILE=$(find . -type f -name "*.dreamless" | head -n 1)

  if [ -n "$DREAMLESS_FILE" ]; then
    ui_print "Detected .dreamless file: $DREAMLESS_FILE"
    ui_print " ";
    
    # Extract filename from the .dreamless file and remove the '.dreamless' extension at the top
    FILE_NAME=$(basename "$DREAMLESS_FILE")
    FILE_NAME_NO_EXT=$(echo "$FILE_NAME" | sed 's/\.dreamless$//')
    # Now split the filename without the extension
    UI_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f1)
    CPU_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f2)
    if [ "$CPU_VARIANT" = "uv" ]; then
      GPU_VARIANT="$CPU_VARIANT"
      CPU_VARIANT=""  # blank it
    else
      GPU_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f3)
    fi

    # Fallback for removed -ir variant
    if [ "$UI_VARIANT" = "ir" ]; then
      UI_VARIANT="aosp"
    fi

    # Log the parsed variants
    ui_print "UI variant: $UI_VARIANT"
    ui_print "CPU variant: $CPU_VARIANT"
    ui_print "GPU variant: $GPU_VARIANT"
    ui_print " ";

    # Handle UI variant (AOSP or MIUI)
    case "$UI_VARIANT" in
      miui)
        ui_print "MIUI/HyperOS detected, using MIUI DTBO..."
        mv *-miui-dtbo.img $home/dtbo.img
        rm -f *-aosp-dtbo.img
        ;;
      oplus)
        ui_print "OEM Ports detected, using MIUI DTBO..."
        mv *-miui-dtbo.img $home/dtbo.img
        rm -f *-aosp-dtbo.img
        ;;
      aosp)
        ui_print "AOSP detected, using AOSP DTBO..."
        mv *-aosp-dtbo.img $home/dtbo.img
        rm -f *-miui-dtbo.img
        ;;
      *)
        abort "ERROR!!! Invalid or missing 'ui=' in .dreamless file"
        ;;
    esac
    ui_print " ";

    # Handle CPU and GPU variants (Efficient CPU with UV, etc.)
    if [ "$CPU_VARIANT" = "eff" ]; then
      if [ "$GPU_VARIANT" = "uv" ]; then
        ui_print "Efficient CPU + Undervolted GPU variant detected"
        ui_print "Using that DTB..."
        mv *-effcpu-dtb $home/dtb
        rm -f *-normal-dtb *-effcpu-gpustk-dtb *-normal-gpustk-dtb
      else
        ui_print "Efficient CPU + Stock GPU variant detected"
        ui_print "Using that DTB..."
        mv *-effcpu-gpustk-dtb $home/dtb
        rm -f *-normal-dtb *-effcpu-dtb *-normal-gpustk-dtb
      fi
    else
      if [ "$GPU_VARIANT" = "uv" ]; then
        ui_print "Normal CPU + Undervolted GPU variant detected"
        ui_print "Using that DTB..."
        mv *-normal-dtb $home/dtb
        rm -f *-effcpu-dtb *-normal-gpustk-dtb *-effcpu-gpustk-dtb
      else
        ui_print "Normal CPU + Stock GPU variant detected"
        ui_print "Using that DTB..."
        mv *-normal-gpustk-dtb $home/dtb
        rm -f *-effcpu-dtb *-normal-dtb *-effcpu-gpustk-dtb
      fi
    fi

    # Optionally delete .dreamless file after processing (clean-up)
    rm -f "$DREAMLESS_FILE"
  else
    abort "ERROR!!! No .dreamless file found in zip."
  fi
  
else

  case "$ZIPFILE" in
    *miui*|*MIUI*|*oplus*|*OPLUS*)
      if [[ "$ZIPFILE" == *"oplus"* || "$ZIPFILE" == *"OPLUS"* ]]; then
        ui_print "OEM Ports Detected,"
        ui_print "Using MIUI DTBO... "
      else
        ui_print "MIUI/HyperOS Detected,"
        ui_print "Using MIUI DTBO... "
      fi
      
      mv *-miui-dtbo.img $home/dtbo.img
      rm *-aosp-dtbo.img
    *)
      ui_print "Default variant detected !!!";
      ui_print "Using Regular AOSP DTBO... ";
      mv *-aosp-dtbo.img $home/dtbo.img;
      rm *-miui-dtbo.img;
    ;;
  esac
  ui_print " ";

  case "$ZIPFILE" in
    *-eff*|*-EFF*)
      if echo "$ZIPFILE" | grep -iq "uv"; then
        ui_print "Efficient CPU + Undervolted GPU variant detected"
        ui_print "Using Efficient CPU + UV GPU DTB..."
        mv *-effcpu-dtb $home/dtb
        rm *-normal-dtb *-effcpu-gpustk-dtb *-normal-gpustk-dtb
      else
        ui_print "Efficient CPU + Stock GPU voltage variant detected"
        ui_print "Using Efficient CPU + Stock GPU DTB..."
        mv *-effcpu-gpustk-dtb $home/dtb
        rm *-normal-dtb *-effcpu-dtb *-normal-gpustk-dtb
      fi
      ;;
    *)
      if echo "$ZIPFILE" | grep -iq "uv"; then
        ui_print "Normal CPU + Undervolted GPU variant detected"
        ui_print "Using Normal CPU + UV GPU DTB..."
        mv *-normal-dtb $home/dtb
        rm *-effcpu-dtb *-normal-gpustk-dtb *-effcpu-gpustk-dtb
      else
        ui_print "Normal CPU + Stock GPU voltage variant detected"
        ui_print "Using Normal CPU + Stock GPU DTB..."
        mv *-normal-gpustk-dtb $home/dtb
        rm *-effcpu-dtb *-normal-dtb *-effcpu-gpustk-dtb
      fi
      ;;
  esac
fi

## AnyKernel install
dump_boot;

# Begin Ramdisk Changes

# migrate from /overlay to /overlay.d to enable SAR Magisk
if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi;

write_boot;
## end install
