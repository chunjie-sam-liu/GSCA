import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DefaultComponent } from './default.component';

import { DefaultRoutingModule } from './default-routing.module';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [DefaultComponent],
  imports: [CommonModule, DefaultRoutingModule, SharedModule],
})
export class DefaultModule {}
