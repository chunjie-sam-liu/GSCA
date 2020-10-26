import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ImmuneRoutingModule } from './immune-routing.module';
import { ImmuneComponent } from './immune.component';


@NgModule({
  declarations: [ImmuneComponent],
  imports: [
    CommonModule,
    ImmuneRoutingModule
  ]
})
export class ImmuneModule { }
