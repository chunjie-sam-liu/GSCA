import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MaterialElevationDirective } from './directives/material-elevation.directive';
import { MaterialModule } from './material.module';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { EchartsModule } from './echarts.module';

@NgModule({
  declarations: [MaterialElevationDirective],
  imports: [CommonModule, RouterModule, FormsModule, ReactiveFormsModule, MaterialModule, EchartsModule],
  exports: [MaterialElevationDirective, FormsModule, ReactiveFormsModule, MaterialModule, EchartsModule],
})
export class SharedModule {}
