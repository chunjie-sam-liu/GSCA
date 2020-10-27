import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { ImmuneComponent } from './immune.component';

const routes: Routes = [
  {
    path: '',
    component: ImmuneComponent,
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class ImmuneRoutingModule {}
