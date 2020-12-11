import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DrugRoutingModule } from './drug-routing.module';
import { DrugComponent } from './drug.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { GdscComponent } from './gdsc/gdsc.component';

@NgModule({
  declarations: [DrugComponent, GdscComponent],
  imports: [CommonModule, DrugRoutingModule, SharedModule],
})
export class DrugModule {}
