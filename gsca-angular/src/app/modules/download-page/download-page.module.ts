import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DownloadPageRoutingModule } from './download-page-routing.module';
import { DownloadPageComponent } from './download-page.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [DownloadPageComponent],
  imports: [CommonModule, DownloadPageRoutingModule, SharedModule],
})
export class DownloadPageModule {}
