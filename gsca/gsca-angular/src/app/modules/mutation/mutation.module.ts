import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { MutationRoutingModule } from './mutation-routing.module';
import { MutationComponent } from './mutation.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [MutationComponent],
  imports: [CommonModule, MutationRoutingModule, SharedModule],
})
export class MutationModule {}
