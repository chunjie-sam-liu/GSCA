import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MaterialElevationDirective } from './directives/material-elevation.directive';
import { MaterialModule } from './material.module';

@NgModule({
  declarations: [MaterialElevationDirective],
  imports: [CommonModule, MaterialModule],
  exports: [MaterialElevationDirective, MaterialModule],
})
export class SharedModule {}
