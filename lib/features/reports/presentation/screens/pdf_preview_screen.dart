import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen PDF preview using the `printing` package.
/// Pass [filePath] to display an already-generated PDF file,
/// or [buildDocument] to generate on the fly.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.title,
    this.filePath,
    this.buildDocument,
  }) : assert(
          filePath != null || buildDocument != null,
          'Provide either filePath or buildDocument',
        );

  final String title;
  final String? filePath;

  /// Callback used by [PdfPreview] to get the PDF bytes on demand.
  final LayoutCallback? buildDocument;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        backgroundColor: AppColors.surfaceOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
        elevation: 0,
      ),
      body: PdfPreview(
        maxPageWidth: 900,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        build: buildDocument ?? _buildFromFile,
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildFromFile(PdfPageFormat format) async {
    return await File(filePath!).readAsBytes();
  }
}
