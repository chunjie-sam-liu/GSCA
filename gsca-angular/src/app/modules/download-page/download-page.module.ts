import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DownloadPageRoutingModule } from './download-page-routing.module';
import { DownloadPageComponent } from './download-page.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { MrnaComponent } from './mrna/mrna.component';
import { SnvComponent } from './snv/snv.component';

@NgModule({
  declarations: [DownloadPageComponent, MrnaComponent, SnvComponent],
  imports: [CommonModule, DownloadPageRoutingModule, SharedModule],
})
export class DownloadPageModule {}
