import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DrugComponent } from './drug.component';

const routes: Routes = [
  {
    path: '',
    component: DrugComponent,
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class DrugRoutingModule {}
