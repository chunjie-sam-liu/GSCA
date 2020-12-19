import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneCnvGsvaComponent } from './immune-cnv-gsva.component';

describe('ImmuneCnvGsvaComponent', () => {
  let component: ImmuneCnvGsvaComponent;
  let fixture: ComponentFixture<ImmuneCnvGsvaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneCnvGsvaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneCnvGsvaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
