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
device.name1=alioth
device.name2=aliothin
device.name3=
device.name4=
device.name5=
supported.versions=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
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
    BATTERY_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f1)
    UI_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f2)
    CPU_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f3)
    if [ "$CPU_VARIANT" = "uv" ]; then
      GPU_VARIANT="$CPU_VARIANT"
      CPU_VARIANT=""  # blank it
    else
      GPU_VARIANT=$(echo "$FILE_NAME_NO_EXT" | cut -d'-' -f4)
    fi
    

    # Log the parsed variants
    ui_print "Battery variant: $BATTERY_VARIANT"
    ui_print "UI variant: $UI_VARIANT"
    ui_print "CPU variant: $CPU_VARIANT"
    ui_print "GPU variant: $GPU_VARIANT"
    ui_print " ";

    # Handle battery variant
    case "$BATTERY_VARIANT" in
      stk)
        ui_print "You're using alioth stock battery variant"
        ui_print "Performing necessary DTBO renaming..."
        mv alioth-stock-dtbo-aosp.img alioth-aosp-dtbo.img 
        mv alioth-stock-dtbo-ir.img alioth-ir-dtbo.img
        mv alioth-stock-dtbo-miui.img alioth-miui-dtbo.img
        rm -f alioth-j3s-dtbo-aosp.img alioth-j3s-dtbo-miui.img alioth-j3s-dtbo-ir.img
        ;;
      j3s)
        ui_print "You're using 5000 mAh battery variant"
        ui_print "Performing necessary DTBO renaming..."
        mv alioth-j3s-dtbo-aosp.img alioth-aosp-dtbo.img
        mv alioth-j3s-dtbo-ir.img alioth-ir-dtbo.img
        mv alioth-j3s-dtbo-miui.img alioth-miui-dtbo.img
        rm -f alioth-stock-dtbo-aosp.img alioth-stock-dtbo-miui.img alioth-stock-dtbo-ir.img
        ;;
      *)
        ui_print "Please rename .dreamless file properly"
        abort "ERROR!!! Invalid or missing 'battery=' in .dreamless file"
        ;;
    esac
    ui_print " ";

    # Handle UI variant (AOSP or MIUI)
    case "$UI_VARIANT" in
      miui)
        ui_print "MIUI/HyperOS detected, using MIUI DTBO..."
        mv *-miui-dtbo.img $home/dtbo.img
        rm -f *-aosp-dtbo.img *-ir-dtbo.img
        ;;
      aosp)
        ui_print "AOSP detected, using AOSP DTBO..."
        ui_print "Using Old-IR Implementation..."
        mv *-aosp-dtbo.img $home/dtbo.img
        rm -f *-miui-dtbo.img *-ir-dtbo.img
        ;;
      ir)
        ui_print "AOSP-IR detected, using AOSP-IR DTBO..."
        ui_print "Using New LOS-IR Implementation..."
        mv *-ir-dtbo.img $home/dtbo.img
        rm -f *-miui-dtbo.img *-aosp-dtbo.img
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

  # Battery variant detection with sideload-safe fallback
  case "$ZIPFILE" in
   *-stk*|*-STK*)
      ui_print "You're using alioth stock battery variant"
      ui_print "Performing necessary DTBO renaming..."
      mv alioth-stock-dtbo-aosp.img alioth-aosp-dtbo.img
      mv alioth-stock-dtbo-ir.img alioth-ir-dtbo.img
      mv alioth-stock-dtbo-miui.img alioth-miui-dtbo.img
      rm -f alioth-j3s-dtbo-aosp.img alioth-j3s-dtbo-miui.img alioth-j3s-dtbo-ir.img
      ;;
    *-j3s*|*-J3S*)
      ui_print "You're using 5000 mAh battery variant"
      ui_print "Performing necessary DTBO renaming..."
      mv alioth-j3s-dtbo-aosp.img alioth-aosp-dtbo.img
      mv alioth-j3s-dtbo-ir.img alioth-ir-dtbo.img
      mv alioth-j3s-dtbo-miui.img alioth-miui-dtbo.img
      rm -f alioth-stock-dtbo-aosp.img alioth-stock-dtbo-miui.img alioth-stock-dtbo-ir.img
      ;;
    *)
      ui_print "ERROR!!!, Battery variant not detected!"
      ui_print "Please rename the zip with -stk or -j3s accordingly."
      abort "Exiting to prevent flashing wrong battery variant."
      ;;
  esac
  ui_print " ";

  case "$ZIPFILE" in
    *miui*|*MIUI*)
      ui_print "MIUI/HyperOS Detected,";
      ui_print "Using MIUI DTBO... ";
      mv *-miui-dtbo.img $home/dtbo.img;
      rm *-aosp-dtbo.img;
    ;;
    *ir*|*IR*)
      ui_print "AOSP-IR DTBO Detected,";
      ui_print "Using AOSP-IR DTBO... ";
      ui_print "Using New LOS-IR Implementation... ";
      mv *-ir-dtbo.img $home/dtbo.img;
      rm *-miui-dtbo.img;
    ;;
    *)
      ui_print "Default variant detected !!!";
      ui_print "Using Regular AOSP DTBO... ";
      ui_print "Using Old-IR Implementation... ";
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

## vendor_boot shell variables
block=/dev/block/bootdevice/by-name/vendor_boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# reset for vendor_boot patching
reset_ak;

# vendor_boot install
dump_boot;

write_boot;
## end vendor_boot install