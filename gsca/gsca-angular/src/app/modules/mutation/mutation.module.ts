import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MutationRoutingModule } from './mutation-routing.module';
import { MutationComponent } from './mutation.component';


@NgModule({
  declarations: [MutationComponent],
  imports: [
    CommonModule,
    MutationRoutingModule
  ]
})
export class MutationModule { }
