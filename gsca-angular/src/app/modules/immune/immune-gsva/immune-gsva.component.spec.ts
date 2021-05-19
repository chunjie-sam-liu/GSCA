import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneGsvaComponent } from './immune-gsva.component';

describe('ImmuneGsvaComponent', () => {
  let component: ImmuneGsvaComponent;
  let fixture: ComponentFixture<ImmuneGsvaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneGsvaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneGsvaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
