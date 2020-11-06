import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { NgxEchartsModule } from 'ngx-echarts';
import * as echarts from 'echarts';

@NgModule({
  declarations: [],
  imports: [CommonModule, NgxEchartsModule.forRoot({ echarts })],
  exports: [NgxEchartsModule],
})
export class EchartsModule {}
