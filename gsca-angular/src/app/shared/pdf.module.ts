import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PdfViewerModule } from 'ng2-pdf-viewer';

@NgModule({
  declarations: [],
  imports: [CommonModule, PdfViewerModule],
  exports: [PdfViewerModule],
})
export class PdfModule {}
