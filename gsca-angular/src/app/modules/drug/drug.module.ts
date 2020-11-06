import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DrugRoutingModule } from './drug-routing.module';
import { DrugComponent } from './drug.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [DrugComponent],
  imports: [CommonModule, DrugRoutingModule, SharedModule],
})
export class DrugModule {}
