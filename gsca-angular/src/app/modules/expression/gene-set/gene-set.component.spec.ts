import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GeneSetComponent } from './gene-set.component';

describe('GeneSetComponent', () => {
  let component: GeneSetComponent;
  let fixture: ComponentFixture<GeneSetComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GeneSetComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GeneSetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
