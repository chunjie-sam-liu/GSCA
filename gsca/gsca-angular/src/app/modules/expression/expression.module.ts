import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ExpressionRoutingModule } from './expression-routing.module';
import { ExpressionComponent } from './expression.component';


@NgModule({
  declarations: [ExpressionComponent],
  imports: [
    CommonModule,
    ExpressionRoutingModule
  ]
})
export class ExpressionModule { }
