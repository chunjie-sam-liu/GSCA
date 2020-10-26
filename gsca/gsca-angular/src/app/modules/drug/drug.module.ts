import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { DrugRoutingModule } from './drug-routing.module';
import { DrugComponent } from './drug.component';


@NgModule({
  declarations: [DrugComponent],
  imports: [
    CommonModule,
    DrugRoutingModule
  ]
})
export class DrugModule { }
