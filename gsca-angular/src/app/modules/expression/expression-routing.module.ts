import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { ExpressionComponent } from './expression.component';

const routes: Routes = [
  {
    path: '',
    component: ExpressionComponent,
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class ExpressionRoutingModule {}
