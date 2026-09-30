// tools/capture_camera.c
// Windows Media Foundation Camera Snapshot Tool for CARTAN
// Captures a live frame from physical webcam, downsamples to target resolution,
// and outputs uncompressed 24-bit Windows BMP with CPU cacheline aligned strides.

#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <stdio.h>
#include <stdlib.h>

static inline HRESULT MyGetAttributeSize(IMFAttributes* pAttributes, REFGUID guidKey, UINT32* punWidth, UINT32* punHeight) {
    UINT64 val = 0;
    HRESULT hr = pAttributes->lpVtbl->GetUINT64(pAttributes, guidKey, &val);
    if (SUCCEEDED(hr)) {
        *punWidth = (UINT32)(val >> 32);
        *punHeight = (UINT32)(val & 0xFFFFFFFF);
    }
    return hr;
}

// Write 24-bit bottom-up BMP from 32-bit BGRA buffer with optional downsampling
int write_bmp_24_from_bgra(const char* filename, int src_w, int src_h, const unsigned char* src_data, int target_w, int target_h) {
    BITMAPFILEHEADER bfh;
    BITMAPINFOHEADER bih;
    int row_bytes = ((target_w * 3 + 3) / 4) * 4;
    int pixel_data_size = row_bytes * target_h;
    int file_size = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + pixel_data_size;

    bfh.bfType = 0x4D42; // 'BM'
    bfh.bfSize = file_size;
    bfh.bfReserved1 = 0;
    bfh.bfReserved2 = 0;
    bfh.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

    bih.biSize = sizeof(BITMAPINFOHEADER);
    bih.biWidth = target_w;
    bih.biHeight = target_h; // positive = bottom-up
    bih.biPlanes = 1;
    bih.biBitCount = 24;
    bih.biCompression = BI_RGB;
    bih.biSizeImage = pixel_data_size;
    bih.biXPelsPerMeter = 2835;
    bih.biYPelsPerMeter = 2835;
    bih.biClrUsed = 0;
    bih.biClrImportant = 0;

    FILE* f = fopen(filename, "wb");
    if (!f) {
        fprintf(stderr, "Error: Could not open output file '%s' for writing.\n", filename);
        return 0;
    }
    fwrite(&bfh, sizeof(bfh), 1, f);
    fwrite(&bih, sizeof(bih), 1, f);

    unsigned char* row_buf = (unsigned char*)calloc(row_bytes, 1);
    if (!row_buf) {
        fclose(f);
        return 0;
    }

    int src_stride = src_w * 4; // 32-bit BGRA
    for (int y = 0; y < target_h; y++) {
        // Bottom-up: row index is (target_h - 1 - y)
        int dst_row = target_h - 1 - y;
        int src_y = (dst_row * src_h) / target_h;
        if (src_y >= src_h) src_y = src_h - 1;

        const unsigned char* src_row = src_data + (src_y * src_stride);
        for (int x = 0; x < target_w; x++) {
            int src_x = (x * src_w) / target_w;
            if (src_x >= src_w) src_x = src_w - 1;

            const unsigned char* px = src_row + (src_x * 4);
            row_buf[x * 3 + 0] = px[0]; // B
            row_buf[x * 3 + 1] = px[1]; // G
            row_buf[x * 3 + 2] = px[2]; // R
        }
        fwrite(row_buf, 1, row_bytes, f);
    }

    free(row_buf);
    fclose(f);
    return 1;
}

int main(int argc, char* argv[]) {
    const char* out_path = "scratch/camera_frame.bmp";
    int target_w = 640;
    int target_h = 480;

    if (argc >= 2) out_path = argv[1];
    if (argc >= 3) target_w = atoi(argv[2]);
    if (argc >= 4) target_h = atoi(argv[3]);
    if (target_w <= 0) target_w = 640;
    if (target_h <= 0) target_h = 480;

    CoInitializeEx(NULL, COINIT_MULTITHREADED);
    HRESULT hr = MFStartup(MF_VERSION, MFSTARTUP_NOSOCKET);
    if (FAILED(hr)) {
        fprintf(stderr, "Error: MFStartup failed (0x%08lx).\n", hr);
        CoUninitialize();
        return 2;
    }

    IMFAttributes* pAttributes = NULL;
    hr = MFCreateAttributes(&pAttributes, 1);
    if (FAILED(hr)) {
        MFShutdown();
        CoUninitialize();
        return 2;
    }
    pAttributes->lpVtbl->SetGUID(pAttributes, &MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, &MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);

    IMFActivate** ppDevices = NULL;
    UINT32 count = 0;
    hr = MFEnumDeviceSources(pAttributes, &ppDevices, &count);
    if (FAILED(hr) || count == 0) {
        fprintf(stderr, "Notice: No physical camera devices found.\n");
        pAttributes->lpVtbl->Release(pAttributes);
        MFShutdown();
        CoUninitialize();
        return 2;
    }

    IMFMediaSource* pSource = NULL;
    hr = ppDevices[0]->lpVtbl->ActivateObject(ppDevices[0], &IID_IMFMediaSource, (void**)&pSource);
    if (FAILED(hr)) {
        fprintf(stderr, "Error: Failed to activate camera device source (0x%08lx).\n", hr);
        for (UINT32 i = 0; i < count; i++) ppDevices[i]->lpVtbl->Release(ppDevices[i]);
        CoTaskMemFree(ppDevices);
        pAttributes->lpVtbl->Release(pAttributes);
        MFShutdown();
        CoUninitialize();
        return 2;
    }

    IMFSourceReader* pReader = NULL;
    IMFAttributes* pReaderAttrs = NULL;
    MFCreateAttributes(&pReaderAttrs, 1);
    pReaderAttrs->lpVtbl->SetUINT32(pReaderAttrs, &MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);
    hr = MFCreateSourceReaderFromMediaSource(pSource, pReaderAttrs, &pReader);
    pReaderAttrs->lpVtbl->Release(pReaderAttrs);

    if (FAILED(hr)) {
        fprintf(stderr, "Error: Failed to create SourceReader (0x%08lx).\n", hr);
        pSource->lpVtbl->Release(pSource);
        for (UINT32 i = 0; i < count; i++) ppDevices[i]->lpVtbl->Release(ppDevices[i]);
        CoTaskMemFree(ppDevices);
        pAttributes->lpVtbl->Release(pAttributes);
        MFShutdown();
        CoUninitialize();
        return 2;
    }

    // Configure reader output media type to RGB32 (BGRA)
    IMFMediaType* pType = NULL;
    MFCreateMediaType(&pType);
    pType->lpVtbl->SetGUID(pType, &MF_MT_MAJOR_TYPE, &MFMediaType_Video);
    pType->lpVtbl->SetGUID(pType, &MF_MT_SUBTYPE, &MFVideoFormat_RGB32);
    hr = pReader->lpVtbl->SetCurrentMediaType(pReader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, NULL, pType);
    pType->lpVtbl->Release(pType);

    if (FAILED(hr)) {
        fprintf(stderr, "Error: Failed to set RGB32 media type on source reader (0x%08lx).\n", hr);
        pReader->lpVtbl->Release(pReader);
        pSource->lpVtbl->Release(pSource);
        for (UINT32 i = 0; i < count; i++) ppDevices[i]->lpVtbl->Release(ppDevices[i]);
        CoTaskMemFree(ppDevices);
        pAttributes->lpVtbl->Release(pAttributes);
        MFShutdown();
        CoUninitialize();
        return 2;
    }

    // Query native stream dimensions
    IMFMediaType* pActualType = NULL;
    pReader->lpVtbl->GetCurrentMediaType(pReader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &pActualType);
    UINT32 src_w = 0, src_h = 0;
    MyGetAttributeSize((IMFAttributes*)pActualType, &MF_MT_FRAME_SIZE, &src_w, &src_h);
    pActualType->lpVtbl->Release(pActualType);

    // Warm-up loop: read and discard 8 frames so hardware auto-exposure & white balance converge
    IMFSample* pSample = NULL;
    for (int i = 0; i < 8; i++) {
        DWORD streamIndex = 0, flags = 0;
        LONGLONG timestamp = 0;
        if (pSample) { pSample->lpVtbl->Release(pSample); pSample = NULL; }
        hr = pReader->lpVtbl->ReadSample(pReader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &streamIndex, &flags, &timestamp, &pSample);
        if (FAILED(hr) || (flags & MF_SOURCE_READERF_ENDOFSTREAM)) break;
        if (pSample) Sleep(30);
    }

    if (!pSample) {
        fprintf(stderr, "Error: Failed to capture live video sample from camera.\n");
        pReader->lpVtbl->Release(pReader);
        pSource->lpVtbl->Release(pSource);
        for (UINT32 i = 0; i < count; i++) ppDevices[i]->lpVtbl->Release(ppDevices[i]);
        CoTaskMemFree(ppDevices);
        pAttributes->lpVtbl->Release(pAttributes);
        MFShutdown();
        CoUninitialize();
        return 1;
    }

    IMFMediaBuffer* pBuffer = NULL;
    hr = pSample->lpVtbl->ConvertToContiguousBuffer(pSample, &pBuffer);
    int success = 0;
    if (SUCCEEDED(hr)) {
        BYTE* pData = NULL;
        DWORD maxLen = 0, curLen = 0;
        hr = pBuffer->lpVtbl->Lock(pBuffer, &pData, &maxLen, &curLen);
        if (SUCCEEDED(hr)) {
            success = write_bmp_24_from_bgra(out_path, src_w, src_h, pData, target_w, target_h);
            pBuffer->lpVtbl->Unlock(pBuffer);
        }
        pBuffer->lpVtbl->Release(pBuffer);
    }
    pSample->lpVtbl->Release(pSample);

    pReader->lpVtbl->Release(pReader);
    pSource->lpVtbl->Release(pSource);
    for (UINT32 i = 0; i < count; i++) ppDevices[i]->lpVtbl->Release(ppDevices[i]);
    CoTaskMemFree(ppDevices);
    pAttributes->lpVtbl->Release(pAttributes);

    MFShutdown();
    CoUninitialize();

    if (success) {
        printf("[Camera Capture] Successfully captured %dx%d frame to '%s' (Source: %ux%u).\n",
            target_w, target_h, out_path, src_w, src_h);
        return 0;
    }
    fprintf(stderr, "Error: Failed to write frame to '%s'.\n", out_path);
    return 1;
}
