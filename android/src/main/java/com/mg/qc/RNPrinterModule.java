
package com.mg.qc;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.mg.qc.utils.ThreadPool;
import com.tools.command.EscCommand;
import com.tools.command.LabelCommand;

import java.io.File;
import java.util.Set;
import java.util.Vector;

public class RNPrinterModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private int id = 0;
    private ThreadPool threadPool;

    public RNPrinterModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    private String murl = null;
    private Promise mpromise = null;
    private boolean isInit = false;


    @Override
    public String getName() {
        return "RNPrinter";
    }

    /**
     * 重新连接回收上次连接的对象，避免内存泄漏
     */
    private void closeport() {
        if (DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id] != null && DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].mPort != null) {
            DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].reader.cancel();
            DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].mPort.closePort();
            DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].mPort = null;
        }
    }

    public void open_Bluetooth(String macAddress) {
        closeport();
        /* 初始化话DeviceConnFactoryManager */
        new DeviceConnFactoryManager.Build()
                .setId(id)
                /* 设置连接方式 */
                .setConnMethod(DeviceConnFactoryManager.CONN_METHOD.BLUETOOTH)
                /* 设置连接的蓝牙mac地址 */
                .setMacAddress(macAddress)
                .build();
        /* 打开端口 */
        threadPool = ThreadPool.getInstantiation();
        threadPool.addTask(new Runnable() {
            @Override
            public void run() {
                DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].openPort();
                printData();
            }
        });
    }

    public void initBluetooth() {
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        if (mBluetoothAdapter == null) {
//            promise.reject("-2", "");
        } else {
            if (!mBluetoothAdapter.isEnabled()) {
                Intent enableIntent = new Intent(
                        BluetoothAdapter.ACTION_REQUEST_ENABLE);
//                startActivityForResult(enableIntent,
//                        REQUEST_ENABLE_BT);
            } else {
                Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
//                Log.d("aa", pairedDevices.toString());
                if (pairedDevices.size() > 0) {
                    //  tvPairedDevice.setVisibility(View.VISIBLE);
                    for (BluetoothDevice device : pairedDevices) {
//                        Log.d("aaa", )
                        if (device.getName().equals("1324D-40DCB3")) {
                            open_Bluetooth(device.getAddress());
                            return;
                        }
                    }
                }
            }
        }

    }

    void sendLabel() {
        LabelCommand tsc = new LabelCommand();
        /* 设置标签尺寸，按照实际尺寸设置 */
        tsc.addSize(80, 60);
        tsc.addDensity(LabelCommand.DENSITY.DNESITY14);
        /* 设置标签间隙，按照实际尺寸设置，如果为无间隙纸则设置为0 */
        tsc.addGap(20);
        /* 设置打印方向 */
        tsc.addDirection(LabelCommand.DIRECTION.FORWARD, LabelCommand.MIRROR.NORMAL);
        /* 开启带Response的打印，用于连续打印 */
        tsc.addQueryPrinterStatus(LabelCommand.RESPONSE_MODE.ON);
        /* 设置原点坐标 */
        tsc.addReference(14, 0);
        /* 撕纸模式开启 */
        tsc.addTear(EscCommand.ENABLE.ON);
        /* 清除打印缓冲区 */
        tsc.addCls();
        /* 绘制简体中文 */
//        tsc.addText( 100, 100, LabelCommand.FONTTYPE.SIMPLIFIED_CHINESE, LabelCommand.ROTATION.ROTATION_0, LabelCommand.FONTMUL.MUL_1, LabelCommand.FONTMUL.MUL_1,
//                "Wel11222" );
        /* 绘制图片 */

        if (murl.startsWith("file:")) {
            int i = murl.indexOf("data", 0);
            murl = murl.substring(i, murl.length());
        }
        File mFile = new File(murl);
        if (mFile.exists()) {
            Bitmap bitmap = BitmapFactory.decodeFile(murl);
            tsc.addBitmap(20, 50
                    , LabelCommand.BITMAP_MODE.OVERWRITE, 640, bitmap);
        }

        /* 打印标签 */
        tsc.addPrint(1, 1);
        /* 打印标签后 蜂鸣器响 */

        tsc.addSound(2, 100);
        tsc.addCashdrwer(LabelCommand.FOOT.F5, 255, 255);
        Vector<Byte> datas = tsc.getCommand();
        /* 发送数据 */
//        if ( DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id] == null )
//        {
//            return;
//        }
        DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id].sendDataImmediately(datas);

        mpromise.resolve(200);
    }


    public void printData() {
        if (DeviceConnFactoryManager.getDeviceConnFactoryManagers()[id] == null) {
            return;
        }
        sendLabel();
        return;
    }

    @ReactMethod
    public void print(String url, Promise promise) {
        murl = url;
        mpromise = promise;
        initBluetooth();
    }
}